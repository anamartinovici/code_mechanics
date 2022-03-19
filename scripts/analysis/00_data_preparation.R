
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# ## install packages
# install.packages("here")
# install.packages("tools")
# install.packages("tidyverse")

# load packages --------------------------------------------------------------------

library(here)
library(tools)
library(tidyverse)

# setup --------------------------------------------------------------------

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

# load MNE output and save as .RData --------------------------------------------------------

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
