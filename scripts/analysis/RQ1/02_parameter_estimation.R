
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tidyverse")
# install.packages("brms")

# load packages --------------------------------------------------------------------

library(here)
library(tidyverse)
library(brms)

# setup --------------------------------------------------------------------

# electrodes in ROI
ROI <- c('PO7', 'PO3', 'O1', 'PO4', 'PO8', 'O2', 'POz', 'Oz', 'Iz')

num_chains <- 8 # number of chains = number of cores in processor of computer used for analysis
num_iter <- 2000 # number of samples per chain
num_warmup <- 1000 # number of warm-up samples per chain
num_thin <- 1 # thinning: extract one out of x samples per chain

# load and prepare data  --------------------------------------------------------------------

# extract N1 amplitude from selected ROI and time window
N1 <-
  all_pointsummary %>% 
  filter(
    time >= 100 & time <= 150, # keep only data in selected time window
    electrode %in% ROI # keep only data in ROI 
  ) %>% 
  summarySE(
    data = .,
    measurevar = "mean",
    groupvars = c("ssj", "condition"),
    na.rm = FALSE,
    conf.interval = .95
  )

















