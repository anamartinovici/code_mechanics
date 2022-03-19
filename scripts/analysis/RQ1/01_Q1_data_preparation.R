
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tidyverse")

# load packages --------------------------------------------------------------------

library(here)
library(tidyverse)

# setup --------------------------------------------------------------------

# region of interest
ROI <- c('PO7', 'PO3', 'O1',
         'PO4', 'PO8', 'O2',
         'POz', 'Oz', 'Iz')

# load and manipulate data for statistical analysis --------------------------------------------------------------------

# load .RData file with all ERPs
load(here("data", "processed_data", "ERP", "RData", "all_ERP.RData"))

# subset data for Q1
Q1_ERP <- 
  all_ERP %>%
  # create new columns
  mutate(
    condition = case_when( # manmade/natural conditions
      manmade == 1 ~ "manmade",
      natural == 1 ~ "natural"
    ),
    ROI = rowMeans(select(all_ERP, all_of(ROI))), # row-wise mean of ROI
  .after= "epoch_num"
    ) %>% 
  # filter rows according to conditions of interest
  filter(!is.na(condition)) %>% 
  # keep only necessary columns
  select(ssj, time, condition, ROI)
  
# save as .RData (compressed)
save(
  Q1_ERP,
  file = here("data", "processed_data", "ERP", "RData", "Q1_ERP.RData")
)

# END --------------------------------------------------------------------
