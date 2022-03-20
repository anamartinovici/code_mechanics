
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("Rmisc")
# install.packages("here")
# install.packages("tidyverse")
# install.packages("brms")

# load packages --------------------------------------------------------------------

library(Rmisc) # must be loaded before tidyverse (beware some nasty function masking!)
library(here)
library(tidyverse)
library(brms)

# setup --------------------------------------------------------------------

# electrodes in ROI
ROI <- c('PO7', 'PO3', 'O1', 'PO4', 'PO8', 'O2', 'POz', 'Oz', 'Iz')

# setup STAN
num_chains <- 8 # number of chains = number of processor cores
num_iter <- 2000 # number of samples per chain
num_warmup <- 1000 # number of warm-up samples per chain
num_thin <- 1 # thinning: extract one out of x samples per chain

# priors  --------------------------------------------------------------------

# informative priors
priors <- c(
  prior("normal(-4, 3)", class = "b", coef = "Intercept"),
  prior("normal(0, 3)", class = "b"),
  set_prior("student_t(3, 0, 2)", class = "sd")
)

# load and prepare data  --------------------------------------------------------------------

# list of .RData files in directory
list_RData <-
  list.files(
    path = here("data", "processed_data", "ERP", "RData"),
    pattern = "_ERP.RData"
  )

# preallocate data frame with all N1 data
all_N1 <- NULL

# yes, I know I shouldn't use loops in R
for (i in list_RData) {
  
  # load .RData
  load(here("data", "processed_data", "ERP", "RData", i))

  # extract N1 amplitude from selected ROI and time window
  N1 <-
    ERP %>%
    # create new column
    mutate(
      condition = case_when( # manmade/natural conditions
        manmade == 1 ~ "manmade",
        natural == 1 ~ "natural"
      )
    ) %>%
    select(ssj, time, epoch_num, condition, all_of(ROI)) %>% # keep only columns of interest
    filter(time >= 100 & time <= 150) %>% # keep only data in selected time window
    pivot_longer(
      !c(ssj, time, epoch_num, condition), # keep as columns
      names_to = "electrode",
      values_to = "amplitude"
    ) %>% 
    summarySEwithin(
      data = .,
      measurevar = "amplitude",
      withinvars = c("epoch_num", "condition"),
      idvar = "ssj",
      na.rm = FALSE,
      conf.interval = .95
    ) %>% 
    add_column(
      ssj = sub("_.*", "", i), # add column with participant number
      .before = "epoch_num"
    ) %>% 
    select(-c(N, sd, se, ci)) %>% # remove unnecessary columns
    na.omit # drop NAs
    
  # all N1 data
  all_N1 <- rbind(all_N1, N1)
  
}

# sampling  --------------------------------------------------------------------

# model
N1_brms <-
  brm(
    amplitude ~ 0 + Intercept + condition + (1 + condition | ssj),
    # amplitude ~ 0 + Intercept + condition + (1 + condition | ssj) + (1 + condition  | epoch_num),
    data = all_N1,
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
    file = here("data", "processed_data", "ERP", "models", "N1_brms.rds")
  )








