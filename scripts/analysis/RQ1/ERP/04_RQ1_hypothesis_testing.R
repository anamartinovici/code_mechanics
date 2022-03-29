
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

# model
model_path <- here("data", "processed_data", "ERP", "models", "RQ1")

# results
results_path <- here("results", "RQ1", "ERP")

# load data --------------------------------------------------------------------

# results of model fit
m <- readRDS(here(model_path, "RQ1.rds"))

# hypothesis testing via Region of Practical Equivalence (ROPE) --------------------------------------------------------

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
all_equivalence_test <- NULL

# yes, I know I shouldn't use loops in R
for (i in 1:nrow(range_ropeHDI)) {
  
  res <-
    m %>%
    emmeans(~ condition_RQ1) %>% # estimated marginal means
    pairs() %>% # posterior distributions of difference
    equivalence_test(
      range = c(pull(range_ropeHDI[i, "low_ROPE"]), pull(range_ropeHDI[i, "high_ROPE"])), # ROPE
      ci = 1 # proportion of the posterior distribution that falls within the ROPE
    )
  
  # extract values from results
  equivalence_test <- 
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
  all_equivalence_test <- rbind(all_equivalence_test, equivalence_test) 
  
}
  
all_equivalence_test

# save as .rds
saveRDS(
  all_equivalence_test,
  file = here(results_path, "equivalence_test.rds")
)

# Results: 95% of the posterior distribution 
# of the ERP amplitude difference between conditions
# is outside of a region of practical equivalence up until ±0.07 µV.
# Interpretation: we reject the null hypothesis that the two conditions
# elicit similar ERP amplitudes within ±0.07 µV.

# END --------------------------------------------------------------------
