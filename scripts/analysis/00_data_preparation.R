
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tools")
# install.packages("tidyverse")

# load packages --------------------------------------------------------------------

library(here)
library(tools)
library(tidyverse)

# set directories for .RData files --------------------------------------------------------------------

# pandas data frames
orig_path <- here("data", "processed_data", "ERP", "data_frames")

# ERPs, all conditions
data_path <- here("data", "processed_data", "ERP", "RData")
# create directory if it doesn't exist
if (dir.exists(data_path)) {
  print(paste0("The directory '", data_path, "' already exists."))
} else {
  dir.create(path = data_path)
  print(paste0("Directory '", data_path, "' created."))
}

# setup: channels --------------------------------------------------------------------

# list channels to exclude (non-scalp)
exclude_chans <-
  c(
    "VEOG", "HEOG", "IO1", "IO2", "Afp9", "Afp10", # ocular channels
    "M1", "M2" # mastoid channels
  )

# setup: triggers --------------------------------------------------------------------

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
  pull(trigger) # extract as vector
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

# save MNE output as.RData --------------------------------------------------------

# list of .csv files in directory
list_csv <-
  list.files(
    path = orig_path,
    pattern = ".csv"
  )

# yes, I know I shouldn't use loops in R
for (i in list_csv) {
  
  ERP <-
    # load data
    read_csv(
      here(orig_path, i),
      show_col_types = FALSE,
      progress = FALSE
    ) %>%
    # rename columns
    rename("epoch_num" = "epoch") %>%
    rename("trigger" = "condition") %>%
    # relocate columns
    relocate(time, .after = "epoch_num") %>%
    relocate(trigger, .after = "epoch_num") %>%
    # add participant column
    # (separate call from mutate() because the position is different)
    add_column(
      ssj = as_factor(file_path_sans_ext(i)),
      .before = "epoch_num"
    ) %>%
    # add condition-specific columns
    mutate(
      condition_RQ1 = case_when(
        trigger %in% trigs_Q1_manmade ~ "manmade",
        trigger %in% trigs_Q1_natural ~ "natural"
      ),
      condition_RQ2 = case_when(
        trigger %in% trigs_Q2_new ~ "new",
        trigger %in% trigs_Q2_old ~ "old"
      ),
      condition_RQ3 = case_when(
        trigger %in% trigs_Q3_old_hit ~ "old_hit",
        trigger %in% trigs_Q3_old_miss ~ "old_miss"
      ),
      condition_RQ4 = case_when(
        trigger %in% trigs_Q4_remembered ~ "remembered",
        trigger %in% trigs_Q4_forgotten ~ "forgotten"
      ),
      .after = "epoch_num"
    ) %>%
    # delete unnecessary columns
    select(-c(
      `...1`,
      trigger,
      all_of(exclude_chans) # non-scalp channels
    ))

  # save as .RData (compressed)
  save(
    ERP,
    file = here(data_path, paste0(file_path_sans_ext(i), "_ERP.RData"))
  )
  
}

# END --------------------------------------------------------------------
