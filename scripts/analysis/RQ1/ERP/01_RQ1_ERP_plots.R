
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("Rmisc")
# install.packages("here")
# install.packages("tidyverse")
# install.packages("viridis")
# install.packages("remotes")
# remotes::install_github("craddm/eegUtils")

# load packages --------------------------------------------------------------------

library(Rmisc) # must be loaded before tidyverse (beware some nasty function masking!)
library(here)
library(tidyverse)
library(viridis)
library(eegUtils)

# set directories --------------------------------------------------------------------

# ERP data
ERP_path <- here("data", "processed_data", "ERP", "RData", "RQ1")

# results
results_path <- here("results", "RQ1", "ERP")
# create directory if it doesn't exist
if (dir.exists(results_path)) {
  print(paste0("The directory '", results_path, "' already exists."))
} else {
  dir.create(path = results_path)
  print(paste0("Directory '", results_path, "' created."))
}

# setup: channels --------------------------------------------------------------------

# list channels to exclude (non-scalp)
exclude_chans <-
  c(
    "VEOG", "HEOG", "IO1", "IO2", "Afp9", "Afp10", # ocular channels
    "M1", "M2" # mastoid channels
  )

# load electrode locations
chan_locs <-
  import_chans(
    here("data", "original_data", "channel_locations", "chanlocs_ced.txt"),
    format = "spherical",
    file_format = "ced"
    ) %>% 
  filter(!electrode %in% exclude_chans) # exclude non-scalp channels

# setup: plots --------------------------------------------------------------------

# custom ggplot theme
source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

# the values below are obtained by visual inspection, but
# they are included at the beginning of the script for convenience

# time window for mean ERP
time_window <- c(130, 180)

# electrode ROI (region of interest)
ROI <- c("PO7", "PO3", "O1", "PO4", "PO8", "O2")

# load data --------------------------------------------------------------------

# load .RData
load(here("data", "processed_data", "ERP", "RData", "RQ1", "RQ1_plot_all_data.RData"))

# time points for topographies
topo_times <- 
  plot_all_data %>% 
  select(time) %>% 
  filter(time >= 0 & time <= 200) %>% 
  distinct() %>% # extract unique values
  pull(time) # convert as vector

# plot topographies --------------------------------------------------------------------

# by plotting topographies, we will identify 
# the electrodes from which we can prominently record the ERP component

# yes, I know I shouldn't use loops in R
for (i in topo_times) {
  
  # plot topography
  topo <-
    plot_all_data %>%
    filter(time == i) %>% # keep only data in time window of interest
    group_by(electrode) %>% 
    summarize(amplitude = mean(amplitude, na.rm = TRUE), # average across time
              .groups = "keep") %>%
    ungroup() %>% 
    topoplot(
      # limits = c(-4, 4),
      chanLocs = chan_locs,
      method = "Biharmonic",
      palette = "viridis",
      interp_limit = "skirt",
      contour = TRUE,
      chan_marker = "name", # use "point" to see points
      quantity = "amplitude",
      scaling = 1.5 # scale labels and lines
    ) +
    ggtitle(paste0(i, " ms")) +
    theme(plot.title = element_text(size = 28, hjust = .5, face = "bold"))
  
  print(topo)
  
}

# the ROI (region of interest) comprises the following electrodes:
# "PO7", "PO3", "O1", "PO4", "PO8", "O2"

# plot time series (grand average, only ROI) --------------------------------------------------------------------

timeseries_grand_average_ROI <-
  plot_all_data %>% 
  filter(electrode %in% ROI) %>% # keep only electrodes in ROI
  group_by(ssj, electrode, time) %>% 
  summarize(amplitude = mean(amplitude, na.rm = TRUE),# average across conditions
            .groups = "keep") %>% 
  ungroup() %>% 
  pivot_wider(
    id_cols = c(ssj, time),
    names_from = electrode,
    values_from = amplitude
  ) %>% 
  mutate(ROI_amplitude = rowMeans(select(., all_of(ROI)), na.rm = TRUE)) %>% 
  summarySE( # average across participants
    data = .,
    measurevar = "ROI_amplitude",
    groupvars = "time",
    na.rm = FALSE,
    conf.interval = .95
  ) %>% 
  as_tibble

plot_timeseries_grand_average_ROI <-
  timeseries_grand_average_ROI %>%
  ggplot(
    aes(
      x = time,
      y = ROI_amplitude
    )
  ) +
  geom_vline( # vertical reference line
    xintercept = 0,
    linetype = "solid",
    color = "black",
    size = .8,
    alpha = .4
  ) +
  geom_hline( # horizontal reference line
    yintercept = 0,
    linetype = "solid",
    color = "black",
    size = .8,
    alpha = .4
  ) +
  geom_line( # ROI amplitude
    size = 1,
    color = "#3B528BFF", # blue
    alpha = .6
  ) +
  geom_ribbon( # 95% CI
    aes(
      ymin = ROI_amplitude - ci,
      ymax = ROI_amplitude + ci
    ),
    linetype = "dotted",
    color = "#3B528BFF", # blue
    size = .1,
    alpha = .1,
    show.legend = FALSE
  ) +
  labs(
    title = "grand average (ROI)", # title & axes labels
    x = "time (ms)",
    y = expression(paste("amplitude (", mu, "V)"))
  ) +
  scale_x_continuous(breaks = seq(-200, 500, 50)) + # x-axis: tick marks
  scale_y_reverse(
    breaks = seq(-2, 14, 2), # y-axis: tick marks
    limits = c(14, -2)
  ) +
  annotate("rect",
           xmin = time_window[1],
           xmax = time_window[2],
           ymin = 1,
           ymax = 8,
           linetype = "solid",
           size = 1.5,
           color = "#de1d1d",
           alpha = 0
  ) +
  theme_custom

plot_timeseries_grand_average_ROI

# save as.png
ggsave(
  filename = "timeseries_grand_average_ROI.png",
  plot = plot_timeseries_grand_average_ROI,
  device = "png",
  path = results_path,
  scale = 5,
  width = 1024,
  height = 768,
  units = "px",
  dpi = 600
)

# based on the grand average, we identify
# the time window between 130 - 180 ms

# topography in selected time window --------------------------------------------------------------------

topo_grand_average_ROI <- 
  plot_all_data %>%
  filter(time >= time_window[1] & time <= time_window[2]) %>% # keep only data in time window of interest
  group_by(electrode) %>%
  summarize(amplitude = mean(amplitude, na.rm = TRUE), # average across time
            .groups = "keep") %>% 
  ungroup() %>%
  topoplot(
    limits = c(-4, 4),
    chanLocs = chan_locs,
    method = "Biharmonic",
    palette = "viridis",
    interp_limit = "skirt",
    contour = TRUE,
    chan_marker = "point", # use "name" to see electrode label
    quantity = "amplitude",
    highlights = ROI,
    scaling = 2 # scale labels and lines
  ) +
  ggtitle(paste0(time_window[1], " - ", time_window[2], " ms")) +
  theme(plot.title = element_text(size = 28, hjust = .5, face = "bold"))

topo_grand_average_ROI

# save as.png
ggsave(
  filename = "topo_grand_average_ROI.png",
  plot = topo_grand_average_ROI,
  device = "png",
  path = results_path,
  scale = 5,
  width = 1024,
  height = 768,
  units = "px",
  dpi = 600,
  bg = "white"
)

# END --------------------------------------------------------------------
