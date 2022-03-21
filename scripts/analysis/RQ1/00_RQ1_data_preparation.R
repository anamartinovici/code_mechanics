
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

# ERPs, RQ1
data_path_RQ1 <- here("data", "processed_data", "ERP", "RData", "RQ1")
# create directory if it doesn't exist
if (dir.exists(data_path_RQ1)) {
  print(paste0("The directory '", data_path_RQ1, "' already exists."))
} else {
  dir.create(path = data_path_RQ1)
  print(paste0("Directory '", data_path_RQ1, "' created."))
}

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
    select(-c(epoch_num, condition_RQ2, condition_RQ3, condition_RQ4)) %>% 
    # convert to long format
    pivot_longer(
      !c(ssj, time, condition_RQ1), # keep as columns
      names_to = "electrode",
      values_to = "amplitude"
    ) %>%
    group_by(ssj, time, condition_RQ1, electrode) %>% 
    summarize(
      amplitude = mean(amplitude, na.rm = TRUE), # average across trials
      .groups = "keep"
    ) %>% 
    ungroup()
  
  # all trial-averaged data
  plot_all_data <- rbind(plot_all_data, plot_ERP_long)
  
}

# save as .RData (compressed)
save(
  plot_all_data,
  file = here(data_path_RQ1, "RQ1_plot_all_data.RData" )
)

# END --------------------------------------------------------------------
