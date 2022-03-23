
# RNG --------------------------------------------------------

seed_smorfia <- 10 # E' fasule!
set.seed(seed_smorfia) # RNG seed

# Install packages --------------------------------------------------------

# # data wrangling
# install.packages("here")
# install.packages("tidyverse")
# # statistics
# install.packages("emmeans")
# install.packages("bayestestR")

# Load packages --------------------------------------------------------

# data wrangling
library(here)
library(tidyverse)
# statistics
library(emmeans)
library(bayestestR)

# Model --------------------------------------------------------

brms_stim5_C1 <-
  readRDS(
    here("models", "prereg", "brms_stim5_prereg_preproc_C1.rds")
  )

# Hypothesis testing --------------------------------------------------------

ropeHDI <- c(-.05, .05) # ROPE

equivalence_test_cond_brms_stim5_C1 <-
  brms_stim5_C1 %>%
  emmeans(~condition) %>% # estimated marginal means
  pairs() %>% # posterior distributions of differences
  equivalence_test(
    range = ropeHDI, # ROPE
    ci = .95 # HDI
  )

equivalence_test_cond_brms_stim5_C1

# END --------------------------------------------------------
