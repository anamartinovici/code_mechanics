args = commandArgs(TRUE)

if (length(args) == 0) {
	stop("You need to provide arguments", call. = FALSE)
} else {
	project_seed       <- as.numeric(args[1])
	path_to_output_dir <- args[2]
}

cat(paste("\n", "\n", "\n", 
		  "start 02_RQ1_parameter_estimation.R",
		  "\n", "\n", "\n", sep = ""))

print(args)

# RNG --------------------------------------------------------

set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tidyverse")
# install.packages("brms")

# load packages --------------------------------------------------------------------

library(here)
library(tidyverse)
library(brms)

# load ERP data  --------------------------------------------------------------------

load(here("data_in_repo", "processed_data", "RQ1", "RQ1_stats_all_data.RData"))

# setup: STAN --------------------------------------------------------------------

num_chains <- 4 # number of chains = number of processor cores
num_iter   <- 4000 # number of samples per chain
num_warmup <- 2000 # number of warm-up samples per chain
num_thin   <- 1 # thinning: extract one out of x samples per chain

# priors  --------------------------------------------------------------------

# informative priors (based on grand average)
priors <- c(
  prior("normal(4, 2)", class = "b", coef = "Intercept"), 
  prior("normal(0, 3)", class = "b"),
  prior("student_t(3, 0, 2)", class = "sd")
)

# sampling  --------------------------------------------------------------------

m <-
  brm(
    amplitude ~ 0 + Intercept + condition_RQ1 + (1 + condition_RQ1 | ssj) + (1 + condition_RQ1  | epoch_num),
    data = stats_all_data,
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
    file = paste0(path_to_output_dir, "RQ1.rds"),
    file_refit = "always" # plausible options: "on_change" or "always"
  )

# END  --------------------------------------------------------------------
