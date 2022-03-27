args = commandArgs(TRUE)

if (length(args) == 0) {
	stop("You need to provide arguments", call. = FALSE)
} else {
	project_seed             <- as.numeric(args[1])
	path_to_ERP_step3_output <- args[2]
	path_to_ERP_RQ1_data     <- args[3]
}

cat(paste("\n", "\n", "\n", 
		  "start 00_RQ1_data_preparation.R",
		  "\n", "\n", "\n", sep = ""))

print(args)

# RNG --------------------------------------------------------

set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tidyverse")

# load packages --------------------------------------------------------------------

library(here)
library(tidyverse)

# setup: N1 --------------------------------------------------------------------

# time window for mean N1
time_window <- c(130, 180)

# electrode ROI (region of interest)
ROI <- c("PO7", "PO3", "O1", "PO4", "PO8", "O2")

# trial-averaged data for plotting -----------------------------------------------------------------------

# list of .RData files in directory
plot_list_RData <-
  list.files(
    path = path_to_ERP_step3_output,
    pattern = ".RData"
  )

# preallocate data frame with all trial-averaged data
plot_all_data <- NULL

# preallocate data frame with all N1 data
all_N1 <- NULL

# yes, I know I shouldn't use loops in R
for (i in plot_list_RData) {
  
  # load participant-specific .RData
  load(here(path_to_ERP_step3_output, i))
  
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
    ungroup() %>% 
    na.omit # delete NAs
  
  # all trial-averaged data
  plot_all_data <- rbind(plot_all_data, plot_ERP_long)
  
  
  # extract N1 amplitude from selected ROI and time window
  N1 <-
  	ERP %>%
  	select(ssj, epoch_num, time, condition_RQ1, all_of(ROI)) %>% # keep only columns of interest
  	filter(time >= time_window[1] & time <= time_window[2]) %>% # keep only data in selected time window
  	na.omit %>% # delete NAs
  	pivot_longer(
  		all_of(ROI), 
  		names_to = "electrode",
  		values_to = "amplitude"
  	) %>% 
  	group_by(ssj, epoch_num, condition_RQ1) %>% 
  	summarize(amplitude = mean(amplitude, na.rm = TRUE), # average activity in ROI and time window
  			  .groups = "keep") %>% 
  	ungroup()
  
  # all N1 data
  all_N1 <- rbind(all_N1, N1)
}

# save as .RData (compressed)
save(
  plot_all_data,
  file = here(path_to_ERP_RQ1_data, "RQ1_plot_all_data.RData")
)

# save as .RData (compressed)
save(
  all_N1,
  file = here(path_to_ERP_RQ1_data, "RQ1_all_N1.RData" )
)

# END --------------------------------------------------------------------
