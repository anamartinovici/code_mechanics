
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tidyverse")
# install.packages("emmeans")
# install.packages("bayestestR")

# load packages --------------------------------------------------------------------

library(here)
library(tidyverse)
library(emmeans)
library(bayestestR)

# set directories --------------------------------------------------------------------

# # N1 data
# N1_path <- here("data", "processed_data", "ERP", "RData", "RQ1")

# results of model fit
model_path <- here("data", "processed_data", "ERP", "models", "RQ1")

# load data --------------------------------------------------------------------

# results of model fit
N1_brms <- readRDS(here(model_path, "N1_brms_2022-03-22.rds"))

# hypothesis testing via Region of Practical Equivalence (ROPE): single ROPE --------------------------------------------------------

# ROPE is arbitrarily set at ±0.05 µV, 
# 10 times smaller than the minimum expected 
# amplitude difference between conditions (0.5 µV)
ropeHDI <- c(-.05, .05) 

equivalence_test_N1_brms <-
  N1_brms %>%
  emmeans(~ condition_RQ1) %>% # estimated marginal means
  pairs() %>% # posterior distributions of differences
  equivalence_test(
    range = ropeHDI, # ROPE
    ci = .95 # HDI
  )

equivalence_test_N1_brms

# hypothesis testing via Region of Practical Equivalence (ROPE): range of ROPEs --------------------------------------------------------

# range of plausible ROPE values
# (between ±0.05 and ±0.5 µV in steps of 0.01 µV)
range_ropeHDI <- tibble(
  low_ROPE = rev(seq(from = -0.5, to = -0.05, by = 0.01)),
  high_ROPE = seq(from = 0.05, to = 0.5, by = 0.01)
  )

# preallocate data frame with all ROPE results
all_equivalence_test_N1_brms <- NULL

# yes, I know I shouldn't use loops in R
for (i in 1:nrow(range_ropeHDI)) {
  
  res <-
    N1_brms %>%
    emmeans(~ condition_RQ1) %>%
    pairs() %>%
    equivalence_test(
      range = c(pull(range_ropeHDI[i, "low_ROPE"]), pull(range_ropeHDI[i, "high_ROPE"])),
      ci = .95
    )
  
  # extract values from results
  equivalence_test_N1_brms <- 
    tibble(
      Parameter = res$Parameter,
      CI = res$CI,
      ROPE_low = res$ROPE_low,
      ROPE_high = res$ROPE_high,
      ROPE_Percentage = res$ROPE_Percentage,
      ROPE_Equivalence = res$ROPE_Equivalence,
      HDI_low = res$HDI_low,
      HDI_high = res$HDI_high
    )
  
  # merge results using all ROPEs
  all_equivalence_test_N1_brms <- rbind(all_equivalence_test_N1_brms, equivalence_test_N1_brms) 
  
} 
  
all_equivalence_test_N1_brms

# Results: 95% of the posterior distribution 
# of the N1 amplitude difference between manmade and natural scenes
# is outside of a region of practical equivalence up until 0.09 µV.
# In other words, manmade scenes elicit an N1 whose amplitude is at most 
# 0.09 µV larger than the N1 elicited by natural scenes.

# END --------------------------------------------------------------------
