
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

# setup --------------------------------------------------------------------

source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

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

# time window for mean N1
time_window <- c(100, 150)
# electrode ROI (region of interest)
ROI <- c("PO7", "PO3", "O1", "PO4", "PO8", "O2")
# these values are obtained by visual inspection, but
# they are included at the beginning of the script for convenience

# load and prepare data --------------------------------------------------------------------

# load .RData
load(here("data", "processed_data", "ERP", "RData", "Q1", "all_pointsummary.RData"))

# grand average
grand_average <- 
  all_pointsummary %>% 
  summarySE(
    data = .,
    measurevar = "mean",
    groupvars = c("time", "electrode"),
    na.rm = FALSE,
    conf.interval = .95
    ) %>% 
  as_tibble

# plot time series (grand average) --------------------------------------------------------------------

timeseries_grand_average <-
  grand_average %>%
  ggplot(
    aes(
      x = time,
      y = mean,
      group = electrode
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
      ymin = mean - ci,
      ymax = mean + ci
    ),
    # linetype = "dotted",
    color = "#3B528BFF", # blue
    size = .1,
    alpha = .1,
    show.legend = FALSE
  ) +
  labs(
    title = "grand average", # title & axes labels
    x = "time (ms)",
    y = expression(paste("amplitude (", mu, "V)"))
  ) +
  scale_x_continuous(breaks = seq(-200, 500, 100)) + # x-axis: tick marks
  scale_y_reverse(
    breaks = seq(-16, 16, 2), # y-axis: tick marks
    limits = c(16, -16)
  ) +
  annotate("rect",
           xmin = time_window[1],
           xmax = time_window[2],
           ymin = -4,
           ymax = 8,
           linetype = "solid",
           size = 2,
           color = "#de1d1d",
           alpha = 0
  ) +
  theme_custom

timeseries_grand_average

# based on the grand average, we identify
# a time window for the N1 between 100 - 150 ms

# plot topography --------------------------------------------------------------------

# by plotting the topography, we will identify 
# the electrodes from which we can prominently record the N1

topo_data <- 
  all_pointsummary %>% 
  filter(time >= time_window[1] & time <= time_window[2]) %>% # keep only data in time window of interest
  summarySE(
    data = .,
    measurevar = "mean",
    groupvars = "electrode",
    na.rm = FALSE,
    conf.interval = .95
  ) %>% 
  as_tibble %>% 
  select(electrode, amplitude = mean)

# plot topography
topo <- 
  topo_data %>% 
  topoplot(
    .,
    limits = c(-5, 5),
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
  ggtitle("N1 (localizer)") +
  theme(plot.title = element_text(size = 28, hjust = .5, face = "bold"))

topo

# the ROI (region of interest) comprises the following electrodes:
# "PO7", "PO3", "O1", "PO4", "PO8", "O2"

# plot time series (grand average, only ROI) --------------------------------------------------------------------






timeseries_grand_average_ROI <-
  grand_average %>%
  filter(electrode %in% ROI) %>% 
  ggplot(
    aes(
      x = time,
      y = mean,
      group = electrode
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
      ymin = mean - ci,
      ymax = mean + ci
    ),
    # linetype = "dotted",
    color = "#3B528BFF", # blue
    size = .1,
    alpha = .1,
    show.legend = FALSE
  ) +
  labs(
    title = "grand average", # title & axes labels
    x = "time (ms)",
    y = expression(paste("amplitude (", mu, "V)"))
  ) +
  scale_x_continuous(breaks = seq(-200, 500, 100)) + # x-axis: tick marks
  scale_y_reverse(
    breaks = seq(-2, 16, 2), # y-axis: tick marks
    limits = c(16, -2)
  ) +
  annotate("rect",
           xmin = time_window[1],
           xmax = time_window[2],
           ymin = -2,
           ymax = 9,
           linetype = "solid",
           size = 2,
           color = "#de1d1d",
           alpha = 0
  ) +
  theme_custom

timeseries_grand_average_ROI

# END --------------------------------------------------------------------
