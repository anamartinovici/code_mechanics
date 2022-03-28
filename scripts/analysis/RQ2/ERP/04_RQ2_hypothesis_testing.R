
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

# results of model fit
model_path <- here("data", "processed_data", "ERP", "models", "RQ2")

# load data --------------------------------------------------------------------

# results of model fit
ERP_novelty_brms <- readRDS(here(model_path, "ERP_novelty_brms_2022-03-26.rds"))

# hypothesis testing via Region of Practical Equivalence (ROPE): range of ROPEs --------------------------------------------------------

# If the HDI is completely outside the ROPE, the “null hypothesis” for this parameter is “rejected”.
# If the ROPE completely covers the HDI, i.e., all most credible values of a parameter are inside the region of practical equivalence, the null hypothesis is "accepted". 
# Else, it’s unclear whether the null hypothesis should be accepted or rejected ("undecided").

# We use the full ROPE, i.e., 100% of the HDI (for details, see https://doi.org/10.3389/fpsyg.2019.02767).
# The null hypothesis is rejected or accepted if the percentage of the posterior within the ROPE 
# is smaller than 2.5% or greater than 97.5%. 
# Desirable results are low proportions inside the ROPE (the closer to zero the better).

# range of plausible ROPE values
# (between ±0.05 and ±0.5 µV in steps of 0.01 µV)
range_ropeHDI <- tibble(
  low_ROPE = rev(seq(from = -0.5, to = -0.05, by = 0.01)),
  high_ROPE = seq(from = 0.05, to = 0.5, by = 0.01)
  )

# preallocate data frame with all ROPE results
all_equivalence_test_ERP_novelty_brms <- NULL

# yes, I know I shouldn't use loops in R
for (i in 1:nrow(range_ropeHDI)) {
  
  res <-
    ERP_novelty_brms %>%
    emmeans(~ condition_RQ2) %>% # estimated marginal means
    pairs() %>% # posterior distributions of difference
    equivalence_test(
      range = c(pull(range_ropeHDI[i, "low_ROPE"]), pull(range_ropeHDI[i, "high_ROPE"])), # ROPE
      ci = 1 # proportion of the **whole posterior distribution** that falls within the ROPE
    )
  
  # extract values from results
  equivalence_test_ERP_novelty_brms <- 
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
  all_equivalence_test_ERP_novelty_brms <- rbind(all_equivalence_test_ERP_novelty_brms, equivalence_test_ERP_novelty_brms) 
  
} 
  
all_equivalence_test_ERP_novelty_brms

# Results: 95% of the posterior distribution 
# of the amplitude difference between new and old scenes
# is outside of a region of practical equivalence up until ±0.29 µV.
# More specifically, new scenes elicit a novelty ERP component 
# whose amplitude is at least 0.29 µV larger (more negative) than a novelty ERP component elicited by old scenes.

# END --------------------------------------------------------------------
