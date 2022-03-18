
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

# load triggers (from TriggerTable.csv)
trigs <- read_csv(
  here("data", "original_data", "events", "TriggerTable.csv"),
  show_col_types = FALSE
)


####################################################
# FROM HERE
####################################################



# combined triggers according to research questions
# Q1
# 'manmade' condition
# NOTE: 'manmade' excludes NAs in behavior: 
# although scene category is independent from response, 
# NAs may reflect drops in attention and, consequently, incomplete stimulus perception
trigs_Q1_manmade = trigs[(trigs['scene_category'] == 'man-made') 
                         & (trigs['behavior'] != 'na')
]['trigger']
# 'natural' condition
# NOTE: 'natural' excludes NAs in behavior: 
# although scene category is independent from response, 
# NAs may reflect drops in attention and, consequently, incomplete stimulus perception
trigs_Q1_natural = trigs[(trigs['scene_category'] == 'natural') 
                         & (trigs['behavior'] != 'na')
]['trigger']
# Q2
# 'new' condition
# NOTE: 'new' excludes NAs in behavior (possible drops in attention)
trigs_Q2_new = trigs[(trigs['old'] == 'new') 
                     & (trigs['behavior'] != 'na')
]['trigger']
# 'old' condition
# NOTE: 'old' excludes NAs in behavior (possible drops in attention)
trigs_Q2_old = trigs[(trigs['old'] == 'old') 
                     & (trigs['behavior'] != 'na')
]['trigger']
# Q3
# 'old-hit'
# NOTE: 'old-hit' must only include 
# old in presentation and hit in behavior but can include NAs in memory: 
# the point is whether the image has been initially successfully categorized as old, 
# regardless of whether it's recognized as such in subsequent presentations
trigs_Q3_old_hit = trigs[(trigs['old'] == 'old') 
                         & (trigs['behavior'] == 'hit')
]['trigger']
# 'old-miss'
# NOTE: 'old-miss' must only include 
# old in presentation and misses in behavior but can include NAs in memory: 
# the point is whether the image has been initially unsuccessfully categorized as old, 
# regardless of whether it's recognized as such in subsequent presentations
trigs_Q3_old_miss = trigs[(trigs['old'] == 'old') 
                          & (trigs['behavior'] == 'miss/forgotten')
]['trigger']
# Q4
# 'remembered'
# NOTE: 'remembered' can be both 'new' and 'old' and include all behavior
trigs_Q4_remembered = trigs[trigs['subsequent_correct'] == 'subsequent_remembered'
]['trigger']
# 'forgotten' 
# NOTE: 'forgotten' can be both 'new' and 'old' and include all behavior
trigs_Q4_forgotten = trigs[trigs['subsequent_correct'] == 'subsequent_forgotten'
]['trigger']






# load MNE output and save as .RData --------------------------------------------------------

# preallocate variable with epochs of all participants
all_epochs <- NULL

# list of .csv files in directory
list_csv <-
  list.files(
    path = here("data", "processed_data", "ERP", "data_frames"),
    pattern = ".csv"
  )

# yes, I know I shouldn't use loops in R
for (i in list_csv) {
  
  epoch <-
    read_csv( # load data
      here("data", "processed_data", "ERP", "data_frames", i),
      show_col_types = FALSE
    ) %>%
    select(-`...1`) %>% # delete unnecessary column
    mutate(
      ssj = as_factor(file_path_sans_ext(i)), # add participant number
      .before = "time"
    ) %>% 
    select(-all_of(exclude_chans)) %>% # delete non-scalp channels

  
  # add condition column
  
  
  
  all_epochs <- bind_rows(all_epochs, epoch) # merge current data with previous ones
  
}

# save as .RData (compressed)
save(
  all_epochs,
  file = here("data", "processed_data", "ERP", "RData", "all_epochs.RData")
)

# END --------------------------------------------------------------------
