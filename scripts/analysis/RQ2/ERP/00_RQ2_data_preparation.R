
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tidyverse")

# load packages --------------------------------------------------------------------

library(here)
library(tidyverse)

# set directories for .RData files --------------------------------------------------------------------

# ERPs, all conditions
data_path <- here("data", "processed_data", "ERP", "RData")

# ERPs, RQ2
data_path_RQ2 <- here("data", "processed_data", "ERP", "RData", "RQ2")
# create directory if it doesn't exist
if (dir.exists(data_path_RQ2)) {
  print(paste0("The directory '", data_path_RQ2, "' already exists."))
} else {
  dir.create(path = data_path_RQ2)
  print(paste0("Directory '", data_path_RQ2, "' created."))
}

# setup: ERP_novelty --------------------------------------------------------------------

# time window for mean ERP_novelty
time_window <- c(300, 500)

# electrode ROI (region of interest)
ROI <- c("AF3", "AFz", "AF4", "F1", "Fz", "F2", "FC1", "FC2", "FCz")

# trial-averaged data for plotting -----------------------------------------------------------------------

# list of .RData files in directory
plot_list_RData <-
  list.files(
    path = data_path,
    pattern = ".RData"
  )

# preallocate data frame with all trial-averaged data
plot_all_data <- NULL

# yes, I know I shouldn't use loops in R
for (i in plot_list_RData) {
  
  # load .RData
  load(here(data_path, i))
  
  plot_ERP_long <- 
    ERP %>% 
    select(-c(epoch_num, condition_RQ1, condition_RQ3, condition_RQ4)) %>% 
    # convert to long format
    pivot_longer(
      !c(ssj, time, condition_RQ2), # keep as columns
      names_to = "electrode",
      values_to = "amplitude"
    ) %>%
    group_by(ssj, time, condition_RQ2, electrode) %>% 
    summarize(
      amplitude = mean(amplitude, na.rm = TRUE), # average across trials
      .groups = "keep"
    ) %>% 
    ungroup() %>% 
    na.omit # delete NAs
  
  # all trial-averaged data
  plot_all_data <- rbind(plot_all_data, plot_ERP_long)
  
}

# save as .RData (compressed)
save(
  plot_all_data,
  file = here(data_path_RQ2, "RQ2_plot_all_data.RData")
)

# trial data for stats -----------------------------------------------------------------------

stats_list_RData <-
  list.files(
    path = data_path,
    pattern = ".RData"
  )

# preallocate data frame with all N1 data
all_ERP_novelty <- NULL

# yes, I know I shouldn't use loops in R
for (i in stats_list_RData) {
  
  # load .RData
  load(here(data_path, i))
  
  # extract amplitude from selected ROI and time window
  ERP_novelty <-
    ERP %>%
    select(ssj, epoch_num, time, condition_RQ2, all_of(ROI)) %>% # keep only columns of interest
    filter(time >= time_window[1] & time <= time_window[2]) %>% # keep only data in selected time window
    na.omit %>% # delete NAs
    pivot_longer(
      all_of(ROI), 
      names_to = "electrode",
      values_to = "amplitude"
    ) %>% 
    group_by(ssj, epoch_num, condition_RQ2) %>% 
    summarize(amplitude = mean(amplitude, na.rm = TRUE), # average activity in ROI and time window
              .groups = "keep") %>% 
    ungroup()
  
  # all N1 data
  all_ERP_novelty <- rbind(all_ERP_novelty, ERP_novelty)
  
}

# save as .RData (compressed)
save(
  all_ERP_novelty,
  file = here(data_path_RQ2, "RQ2_all_ERP_novelty.RData")
)

# END --------------------------------------------------------------------
