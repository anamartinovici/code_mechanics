
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

# set directories --------------------------------------------------------------------

# data
ERP_path <- here("data", "processed_data", "ERP", "RData", "RQ2")

# model fit
model_path <- here("data", "processed_data", "ERP", "models", "RQ2")
# create directory if it doesn't exist
if (dir.exists(model_path)) {
  print(paste0("The directory '", model_path, "' already exists."))
} else {
  dir.create(path = model_path)
  print(paste0("Directory '", model_path, "' created."))
}

# setup: STAN --------------------------------------------------------------------

num_chains <- 8 # number of chains = number of processor cores
num_iter <- 4000 # number of samples per chain
num_warmup <- 2000 # number of warm-up samples per chain
num_thin <- 1 # thinning: extract one out of x samples per chain

# priors  --------------------------------------------------------------------

# informative priors (based on grand average)
priors <- c(
  prior("normal(-8, 2)", class = "b", coef = "Intercept"), 
  prior("normal(0, 3)", class = "b"),
  prior("student_t(3, 0, 2)", class = "sd")
)

# load data  --------------------------------------------------------------------

load(here(ERP_path, "RQ2_all_ERP_novelty.RData"))

# sampling  --------------------------------------------------------------------

N1_brms <-
  brm(
    amplitude ~ 0 + Intercept + condition_RQ2 + (1 + condition_RQ2 | ssj) + (1 + condition_RQ2  | epoch_num),
    data = all_ERP_novelty,
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
    seed = project_seed,
    file = here(model_path, "ERP_novelty_brms.rds"),
    file_refit = "on_change" # plausible options: "on_change" or "always"
  )

# END  --------------------------------------------------------------------
