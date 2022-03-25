
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

# time points for topographies
topo_times <- c(305, 312, 320, 328, 336, 344, 352, 359, 367, 375, 383, 391, 398, 
                406, 414, 422, 430, 438, 445, 453, 461, 469, 477, 484, 492, 500)

# the values below are obtained by visual inspection, but
# they are included at the beginning of the script for convenience

# time window for mean ERP_novelty
time_window <- c(300, 500)

# electrode ROI (region of interest)
ROI <- c("FC1", "FC2", "FCz")

# load and prepare data --------------------------------------------------------------------

# load .RData
load(here("data", "processed_data", "ERP", "RData", "RQ2", "RQ2_plot_all_data.RData"))

# plot topographies --------------------------------------------------------------------

# by plotting topographies, we will identify 
# the electrodes from which we can prominently record the ERP of interest

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
      chan_marker = "point", # use "name" to see electrode label
      quantity = "amplitude",
      scaling = 2 # scale labels and lines
    ) +
    ggtitle(paste0(i, " ms")) +
    theme(plot.title = element_text(size = 28, hjust = .5, face = "bold"))
  
  print(topo)
  
}

# the ROI (region of interest) comprises the following electrodes:
# "FC1", "FC2", "FCz"

# plot time series (grand average, only ROI) --------------------------------------------------------------------

timeseries_grand_average_ROI <-
  plot_all_data %>% 
  filter(electrode %in% ROI) %>% # keep only electrodes in ROI
  group_by(ssj, electrode, time) %>% 
  summarize(amplitude = mean(amplitude, na.rm = TRUE), # average across conditions
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

timeseries_grand_average_ROI %>%
  ggplot(
    aes(
      x = time,
      y = ROI_amplitude
    )
  ) +
  geom_vline( # vertical reference line
    xintercept = 0,
    linetype = "dashed",
    color = "black",
    size = 1.2,
    alpha = .8
  ) +
  geom_hline( # horizontal reference line
    yintercept = 0,
    linetype = "dashed",
    color = "black",
    size = 1.2,
    alpha = .8
  ) +
  geom_line( # one line per electrode
    size = 1,
    color = "#3B528BFF", # blue
    alpha = .6
  ) +
  geom_ribbon( # 95% CI
    aes(
      ymin = ROI_amplitude - ci,
      ymax = ROI_amplitude + ci
    ),
    # linetype = "dotted",
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
  scale_x_continuous(breaks = seq(-200, 500, 100)) + # x-axis: tick marks
  scale_y_reverse(
    breaks = seq(-10, 2, 2), # y-axis: tick marks
    limits = c(2, -10)
  ) +
  annotate("rect",
           xmin = time_window[1],
           xmax = time_window[2],
           ymin = -9,
           ymax = -4,
           linetype = "solid",
           size = 1.5,
           color = "#de1d1d",
           alpha = 0
  ) +
  theme_custom

# the time window of interest is between 300 - 500 ms

# topography in selected time window --------------------------------------------------------------------

plot_all_data %>%
  filter(time >= time_window[1] & time <= time_window[2]) %>% # keep only data in time window of interest
  group_by(electrode) %>%
  summarize(amplitude = mean(amplitude, na.rm = TRUE), # average across time
            .groups = "keep") %>% 
  ungroup() %>%
  topoplot(
    chanLocs = chan_locs,
    method = "Biharmonic",
    palette = "viridis",
    interp_limit = "skirt",
    contour = TRUE,
    chan_marker = "point", # use "name" to see electrode label
    quantity = "amplitude",
    highlights = c("FC1", "FC2", "FCZ"), # must be specified because some electrodes have different upper- and lower-case letters than ROI
    scaling = 2 # scale labels and lines
  ) +
  ggtitle(paste0(time_window[1], " - ", time_window[2], " ms")) +
  theme(plot.title = element_text(size = 28, hjust = .5, face = "bold"))

# END --------------------------------------------------------------------
