
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

# ERPs, all conditions
data_path <- here("data", "processed_data", "ERP", "RData")

# create directory if it doesn't exist
if (dir.exists(data_path)) {
  print(paste0("The directory '", data_path, "' already exists."))
} else {
  dir.create(path = data_path)
  print(paste0("Directory '", data_path, "' created."))
}

# ERPs, RQ1
data_path_RQ1 <- here("data", "processed_data", "ERP", "RData", "RQ1")

# create directory if it doesn't exist
if (dir.exists(data_path_RQ1)) {
  print(paste0("The directory '", data_path_RQ1, "' already exists."))
} else {
  dir.create(path = data_path_RQ1)
  print(paste0("Directory '", data_path_RQ1, "' created."))
}

# ERPs, RQ2
data_path_RQ2 <- here("data", "processed_data", "ERP", "RData", "RQ2")

# create directory if it doesn't exist
if (dir.exists(data_path_RQ2)) {
  print(paste0("The directory '", data_path_RQ2, "' already exists."))
} else {
  dir.create(path = data_path_RQ2)
  print(paste0("Directory '", data_path_RQ2, "' created."))
}

# ERPs, RQ3
data_path_RQ3 <- here("data", "processed_data", "ERP", "RData", "RQ3")

# create directory if it doesn't exist
if (dir.exists(data_path_RQ3)) {
  print(paste0("The directory '", data_path_RQ3, "' already exists."))
} else {
  dir.create(path = data_path_RQ3)
  print(paste0("Directory '", data_path_RQ3, "' created."))
}

# ERPs, RQ4
data_path_RQ4 <- here("data", "processed_data", "ERP", "RData", "RQ4")

# create directory if it doesn't exist
if (dir.exists(data_path_RQ4)) {
  print(paste0("The directory '", data_path_RQ4, "' already exists."))
} else {
  dir.create(path = data_path_RQ4)
  print(paste0("Directory '", data_path_RQ4, "' created."))
}

# channels --------------------------------------------------------------------

# list channels to exclude (non-scalp)
exclude_chans <-
  c(
    "VEOG", "HEOG", "IO1", "IO2", "Afp9", "Afp10", # ocular channels
    "M1", "M2" # mastoid channels
  )

# triggers --------------------------------------------------------------------

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

# save MNE output --------------------------------------------------------

# list of .csv files in directory
list_csv <-
  list.files(
    path = here("data", "processed_data", "ERP", "data_frames"),
    pattern = ".csv"
  )

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
      manmade = if_else(trigger %in% trigs_Q1_manmade, 1, 0),
      natural = if_else(trigger %in% trigs_Q1_natural, 1, 0),
      new = if_else(trigger %in% trigs_Q2_new, 1, 0),
      old = if_else(trigger %in% trigs_Q2_old, 1, 0),
      old_hit = if_else(trigger %in% trigs_Q3_old_hit, 1, 0),
      old_miss = if_else(trigger %in% trigs_Q3_old_miss, 1, 0),
      remembered = if_else(trigger %in% trigs_Q4_remembered, 1, 0),
      forgotten = if_else(trigger %in% trigs_Q4_forgotten, 1, 0),
      .after = "trigger"
    ) %>% 
    na.omit # drop NAs (if any)

  # save as .RData (compressed)
  save(
    ERP,
    file = here(data_path, paste0(file_path_sans_ext(i), "_ERP.RData"))
    )

  # subset data for RQ1
  RQ1_ERP <-
    ERP %>%
    # create new columns
    mutate(
      condition = case_when( # manmade/natural conditions
        manmade == 1 ~ "manmade",
        natural == 1 ~ "natural"
      ),
      .after = "epoch_num"
    ) %>%
    # filter rows according to conditions of interest (also exclude NAs)
    filter(!is.na(condition)) %>%
    # delete unnecessary columns
    select(-c(epoch_num, trigger, manmade, natural, new, old, old_hit, old_miss, remembered, forgotten))

  # save as .RData (compressed)
  save(
    RQ1_ERP,
    file = here(data_path_RQ1, paste0(file_path_sans_ext(i), "_RQ1_ERP.RData"))
    )

  # subset data for RQ2
  RQ2_ERP <-
    ERP %>%
    mutate(
      condition = case_when( # new/old conditions
        new == 1 ~ "new",
        old == 1 ~ "old"
      ),
      .after = "epoch_num"
    ) %>%
    filter(!is.na(condition)) %>%
    select(-c(epoch_num, trigger, manmade, natural, new, old, old_hit, old_miss, remembered, forgotten))

  # save as .RData (compressed)
  save(
    RQ2_ERP,
    file = here(data_path_RQ2, paste0(file_path_sans_ext(i), "_RQ2_ERP.RData"))
  )

  # subset data for RQ3
  RQ3_ERP <-
    ERP %>%
    mutate(
      condition = case_when( # old-hit/old-miss conditions
        old_hit == 1 ~ "old_hit",
        old_miss == 1 ~ "old_miss"
      ),
      .after = "epoch_num"
    ) %>%
    filter(!is.na(condition)) %>%
    select(-c(epoch_num, trigger, manmade, natural, new, old, old_hit, old_miss, remembered, forgotten))

  # save as .RData (compressed)
  save(
    RQ3_ERP,
    file = here(data_path_RQ3, paste0(file_path_sans_ext(i), "_RQ3_ERP.RData"))
  )

  # subset data for RQ4
  RQ4_ERP <-
    ERP %>%
    mutate(
      condition = case_when( # remembered/forgotten conditions
        remembered == 1 ~ "remembered",
        forgotten == 1 ~ "forgotten"
      ),
      .after = "epoch_num"
    ) %>%
    filter(!is.na(condition)) %>%
    select(-c(epoch_num, trigger, manmade, natural, new, old, old_hit, old_miss, remembered, forgotten))

  # save as .RData (compressed)
  save(
    RQ4_ERP,
    file = here(data_path_RQ4, paste0(file_path_sans_ext(i), "_RQ4_ERP.RData"))
  )
  
}

# Q1, save trial-averaged data -----------------------------------------------------------------------

# list of .RData files in directory
list_RData <-
  list.files(
    path = data_path_RQ1,
    pattern = ".RData"
  )

# preallocate data frame with all trial-averaged data
all_pointsummary <- NULL

# yes, I know I shouldn't use loops in R
for (i in list_RData) {
  
  # load .RData
  load(here(data_path_RQ1, i))
  
  RQ1_ERP_long <- 
    RQ1_ERP %>% 
    # convert to long format
    pivot_longer(
      !c(ssj, time, condition), # keep as columns participant number and time
      names_to = "electrode",
      values_to = "amplitude"
    )
  
  # summarized data from each time point
  RQ1_ERP_long_pointsummary <-
    RQ1_ERP_long %>%
    group_by(time, electrode, condition) %>% 
    summarize(amplitude = mean(amplitude, na.rm = TRUE)) %>% 
    ungroup() %>%
    add_column(
      ssj = sub("_.*", "", i), # add column with participant number
      .before = "time"
    )
  
  # all trial-averaged data
  all_pointsummary <- rbind(all_pointsummary, RQ1_ERP_long_pointsummary)
  
}

# save as .RData (compressed)
save(
  all_pointsummary,
  file = here(data_path_RQ1, "all_pointsummary.RData" )
  )

# END --------------------------------------------------------------------
