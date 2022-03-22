
# RNG --------------------------------------------------------

seed_smorfia <- 10 # E' fasule!
set.seed(seed_smorfia) # RNG seed

# Install packages --------------------------------------------------------

# # data wrangling
# install.packages("here")
# install.packages("tidyverse")
# # statistical analysis
# install.packages("brms")

# Load packages --------------------------------------------------------

# data wrangling
library(here)
library(tidyverse)
# statistical analysis
library(brms)

# Setup brms --------------------------------------------------------

num_chains <- 8 # number of chains = number of cores in processor of computer used for analysis
num_iter <- 2000 # number of samples per chain
num_warmup <- 1000 # number of warm-up samples per chain
num_thin <- 1 # thinning: extract one out of x samples per chain

# Load data --------------------------------------------------------

stim5_C1 <-
  read_csv(
    here("data", "prereg", "preproc", "stim5_prereg_preproc_C1.csv"),
    show_col_types = FALSE
  )

# Priors --------------------------------------------------------

# informative priors
priors <- c(
  prior("normal(-3.5, 3)", class = "b", coef = "Intercept"),
  prior("normal(0, 3)", class = "b"),
  set_prior("student_t(3, 0, 2)", class = "sd")
)

# Sampling --------------------------------------------------------

t0 <- Sys.time() # timer on

# model
brms_stim5_C1 <-
  brm(
    amplitude ~ 0 + Intercept + condition + (1 + condition | participant),
    data = stim5_C1,
    family = gaussian(),
    prior = priors,
    inits = "random",
    control = list(
      adapt_delta = .99,
      max_treedepth = 15
    ),
    chains = num_chains,
    iter = num_iter,
    warmup = num_warmup,
    thin = num_thin,
    algorithm = "sampling",
    cores = num_chains,
    seed = seed_smorfia,
    file = here("models", "prereg", "brms_stim5_prereg_preproc_C1.rds")
  )

t1 <- Sys.time() # timer off

# elapsed time
elapsed_brms_stim5_C1 <- t1 - t0

# save as .rds
saveRDS(
  elapsed_brms_stim5_C1,
  here("models", "prereg", "elapsed", "elapsed_brms_stim5_prereg_preproc_C1.rds")
)

# END --------------------------------------------------------
