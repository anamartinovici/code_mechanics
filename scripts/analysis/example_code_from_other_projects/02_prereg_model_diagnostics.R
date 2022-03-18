
# RNG --------------------------------------------------------

seed_smorfia <- 10 # E' fasule!
set.seed(seed_smorfia) # RNG seed

# Install packages --------------------------------------------------------

# # data wrangling
# install.packages("here")
# install.packages("tidyverse")
# # model diagnostics and visualization
# install.packages("brms")
# install.packages("bayestestR")
# install.packages("viridis")
# install.packages("bayesplot")

# Load packages --------------------------------------------------------

# data wrangling
library(here)
library(tidyverse)
# model diagnostics and visualization
library(brms)
library(bayestestR)
library(viridis)
library(bayesplot)

# Graphics --------------------------------------------------------

source(here("code", "functions", "theme_C1.R")) # custom ggplot theme

# cividis color palette for bayesplot
color_scheme_set("viridisE")

# Data --------------------------------------------------------

# data
stim5_C1 <-
  read_csv(
    here("data", "prereg", "preproc", "stim5_prereg_preproc_C1.csv"),
    show_col_types = FALSE
  )

# model
brms_stim5_C1 <-
  readRDS(
    here("models", "prereg", "brms_stim5_prereg_preproc_C1.rds")
  )

# posterior samples of the posterior predictive distribution
posterior_predict_brms_stim5_C1 <-
  brms_stim5_C1 %>%
  posterior_predict(ndraws = 2000)

# Model Diagnostics: trace plots of MCMC draws --------------------------------------------------------

MCMC_brms_stim5_C1 <-
  plot(brms_stim5_C1, ask = FALSE)

# Model Diagnostics: rank histograms --------------------------------------------------------

rank_brms_stim5_C1 <-
  brms_stim5_C1 %>%
  mcmc_rank_overlay(
    n_bins = 20,
    ref_line = TRUE
  ) +
  ggtitle("Rank histograms") +
  theme_C1

rank_brms_stim5_C1

# Model Diagnostics: posterior predictive checks --------------------------------------------------------

PPC_brms_stim5_C1 <-
  posterior_predict_brms_stim5_C1 %>%
  ppc_stat_grouped(
    y = pull(stim5_C1, amplitude),
    group = pull(stim5_C1, condition),
    stat = "mean"
  ) +
  ggtitle("Posterior predictive samples") +
  theme_C1

PPC_brms_stim5_C1

# Model diagnostics: ESS and Rhat --------------------------------------------------------

ESS_Rhat_PPC_brms_stim5_C1 <-
  describe_posterior(
    brms_stim5_C1,
    centrality = "median",
    dispersion = TRUE,
    ci = .95,
    ci_method = "hdi",
    test = NULL,
    diagnostic = c("Rhat", "ESS"),
    effects = c("all")
  )

ESS_Rhat_PPC_brms_stim5_C1

# END --------------------------------------------------------
