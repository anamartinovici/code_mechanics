
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

# chan_locs <-
#   read_delim(
#     here("data", "original_data", "channel_locations", "chanlocs_ced.txt"),
#     delim = "\t",
#     show_col_types= FALSE
#   ) %>% 
#   select(electrode = labels, theta, radius) %>% 
#   filter(!electrode %in% exclude_chans) %>% # exclude non-scalp channels
#   mutate(
#     theta = as.numeric(theta),
#     radius = as.numeric(radius),
#     radianTheta = pi / 180 * theta, # convert theta values from degrees to radians
#     # Cartesian coordinates
#     x = radius * sin(radianTheta),
#     y = radius * cos(radianTheta)
#   ) %>%
#   .[order(.$electrode, decreasing = FALSE), ] # re-order according to topos

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

# plot time series --------------------------------------------------------------------

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
  theme_custom

timeseries_grand_average

# plot topography --------------------------------------------------------------------

# By plotting the topography,
# we will identify the electrodes from which we can prominently record the N1.
# Based on the grand average above, we identify a time window for the N1
# between 100 - 150 ms.

topo_data <- 
  all_pointsummary %>% 
  filter(time >= 100 & time <= 150) %>% #keep only data in time window of interest
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
    highlights = c('PO7', 'PO3', 'O1', 'PO4', 'PO8', 'O2', 'POz', 'Oz', 'Iz'),
    scaling = 2 # scale labels and lines
  ) +
  ggtitle("N1 (localizer)")
# +
#   theme(plot.margin = unit(c(6, 0, 6, 0), "pt")) # decrease plot margins

topo



























# localizer
N1_ROI_localizer <- 
  all_ERP %>% 
  # compute row-wise mean of selected columns
  mutate(ROI = rowMeans(select(all_ERP, all_of(ROI)))) %>% 
  # condition differences are not needed for collapsed localizer
  filter(`manmade` == 1 | `natural` == 1) %>% 
  # only select necessary columns
  select(ssj, time, ROI) %>% 
  # convert to long format
  pivot_longer(
    !c(ssj, time), # keep participant number and time
    names_to = "electrode",
    values_to = "amplitude"
  )
  












# summarized data from each time point (& within-subject 95% CI)
N1_ROI_localizer_pointsummary <- 
  N1_ROI_localizer %>% 
  summarySEwithin(
    data = .,
    measurevar = "amplitude",
    withinvars = "time",
    idvar = "ssj"
  ) %>%
  mutate(
    time = as.numeric(levels(time))[time] # re-convert time points to numeric
  )

# plot
ggplot(
  N1_ROI_localizer_pointsummary,
  aes(
    x = time,
    y = amplitude
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
  geom_vline( # vertical reference lines
    xintercept = seq(-200, 500, 50),
    linetype = "dotted",
    color = "#999999",
    size = .8,
    alpha = .5
  ) +
  geom_hline( # horizontal reference lines
    yintercept = seq(-1, 8, 1),
    linetype = "dotted",
    color = "#999999",
    size = .8,
    alpha = .5
  ) +
  geom_line( # one line per electrode
    size = 1.2,
    color = "#494847",
    alpha = .8
  ) +
  geom_ribbon( # 95% CI
    aes(
      ymin = amplitude - ci,
      ymax = amplitude + ci
    ),
    linetype = "dotted",
    size = .1,
    alpha = .1,
    show.legend = FALSE
  ) +
  labs(
    title = "", # title & axes labels
    x = "time (ms)",
    y = expression(paste("amplitude (", mu, "V)"))
  ) +
  scale_x_continuous(breaks = seq(-200, 500, 50)) + # x-axis: tick marks
  scale_y_reverse(
    breaks = seq(-1, 8, 1), # y-axis: tick marks
    limits = c(8, -1)
  ) +
  theme_classic(base_size = 20) +
  theme(
    plot.title = element_text(
      size = 28,
      hjust = .5,
      face = "bold"
    ),
    legend.position = "none"
  )


































# OLD --------------------------------------------------------------------

# list channels to exclude (non-scalp)
exclude_chans <-
  c(
    "VEOG", "HEOG", "IO1", "IO2", "Afp9", "Afp10", # ocular channels
    "M1", "M2" # mastoid channels
  )

# load triggers
trigs <- read_csv(
  here("data", "original_data", "events", "TriggerTable.csv"),
  show_col_types = FALSE
)

# combine triggers according to research questions
# Q1
# 'manmade' condition
# NOTE: 'manmade' excludes NAs in behavior:
# although scene category is independent from response,
# NAs may reflect drops in attention and, consequently, incomplete stimulus perception
trigs_Q1_manmade <-
  trigs %>%
  filter(scene_category == "man-made" & behavior != "na") %>%
  pull(trigger)
# 'natural' condition
# NOTE: 'natural' excludes NAs in behavior:
# although scene category is independent from response,
# NAs may reflect drops in attention and, consequently, incomplete stimulus perception
trigs_Q1_natural <-
  trigs %>%
  filter(scene_category == "natural" & behavior != "na") %>%
  pull(trigger)
# Q2
# 'new' condition
# NOTE: 'new' excludes NAs in behavior (possible drops in attention)
trigs_Q2_new <-
  trigs %>%
  filter(old == "new" & behavior != "na") %>%
  pull(trigger)
# 'old' condition
# NOTE: 'old' excludes NAs in behavior (possible drops in attention)
trigs_Q2_old <-
  trigs %>%
  filter(old == "old" & behavior != "na") %>%
  pull(trigger)
# Q3
# 'old-hit'
# NOTE: 'old-hit' must only include
# old in presentation and hit in behavior but can include NAs in memory:
# the point is whether the image has been initially successfully categorized as old,
# regardless of whether it's recognized as such in subsequent presentations
trigs_Q3_old_hit <-
  trigs %>%
  filter(old == "old" & behavior == "hit") %>%
  pull(trigger)
# 'old-miss'
# NOTE: 'old-miss' must only include
# old in presentation and misses in behavior but can include NAs in memory:
# the point is whether the image has been initially unsuccessfully categorized as old,
# regardless of whether it's recognized as such in subsequent presentations
trigs_Q3_old_miss <-
  trigs %>%
  filter(old == "old" & behavior == "miss/forgotten") %>%
  pull(trigger)
# Q4
# 'remembered'
# NOTE: 'remembered' can be both 'new' and 'old' and include all behavior
trigs_Q4_remembered <-
  trigs %>%
  filter(subsequent_correct == "subsequent_remembered") %>%
  pull(trigger)
# 'forgotten'
# NOTE: 'forgotten' can be both 'new' and 'old' and include all behavior
trigs_Q4_forgotten <-
  trigs %>%
  filter(subsequent_correct == "subsequent_forgotten") %>%
  pull(trigger)


# list of .csv files in directory
list_csv <-
  list.files(
    path = here("data", "processed_data", "ERP", "data_frames"),
    pattern = ".csv"
  )

# preallocate variable with epochs of all participants
all_ERP <- NULL

# yes, I know I shouldn't use loops in R
for (i in list_csv) {
  
  ERP <-
    # load data
    read_csv(
      here("data", "processed_data", "ERP", "data_frames", i),
      show_col_types = FALSE,
      progress = FALSE
    ) %>%
    # delete unnecessary column
    select(-c(
      `...1`,
      all_of(exclude_chans) # non-scalp channels
    )) %>%
    # rename column
    rename("epoch_num" = "epoch") %>%
    # relocate columns
    relocate(time, .after = "epoch_num") %>%
    relocate(condition, .after = "epoch_num") %>%
    # add participant column
    # (separate call from mutate() because the position must be different)
    add_column(
      ssj = as_factor(file_path_sans_ext(i)),
      .before = "epoch_num"
    ) %>%
    # add condition-specific columns
    mutate(
      manmade = if_else(condition %in% trigs_Q1_manmade, 1, 0),
      natural = if_else(condition %in% trigs_Q1_natural, 1, 0),
      new = if_else(condition %in% trigs_Q2_new, 1, 0),
      old = if_else(condition %in% trigs_Q2_old, 1, 0),
      old_hit = if_else(condition %in% trigs_Q3_old_hit, 1, 0),
      old_miss = if_else(condition %in% trigs_Q3_old_miss, 1, 0),
      remembered = if_else(condition %in% trigs_Q4_remembered, 1, 0),
      forgotten = if_else(condition %in% trigs_Q4_forgotten, 1, 0),
      .after = "condition"
    )

  # merge current data with previous ones
  all_ERP <- bind_rows(all_ERP, ERP)
  
}

# save as .RData (compressed)
save(
  all_ERP,
  file = here("data", "processed_data", "ERP", "RData", "all_ERP.RData")
)

# END --------------------------------------------------------------------
