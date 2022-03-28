
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tidyverse")
# install.packages("brms")
# install.packages("bayestestR")
# install.packages("bayesplot")
# install.packages("viridis")

# load packages --------------------------------------------------------------------

library(here)
library(tidyverse)
library(brms)
library(bayestestR)
library(bayesplot)
library(viridis)

# set directories --------------------------------------------------------------------

# N1 data
ERP_novelty_path <- here("data", "processed_data", "ERP", "RData", "RQ2")

# results of model fit
model_path <- here("data", "processed_data", "ERP", "models", "RQ2")

# setup: plots --------------------------------------------------------------------

# custom ggplot theme
source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

# cividis color palette for bayesplot
color_scheme_set("viridisE")

# load and prepare data --------------------------------------------------------------------

# ERP novelty data
load(here(ERP_novelty_path, "RQ2_all_ERP_novelty.RData"))

# results of model fit
ERP_novelty_brms <- readRDS(here(model_path, "ERP_novelty_brms_2022-03-26.rds"))

# posterior samples of the posterior predictive distribution
posterior_predict_ERP_novelty_brms <-
  ERP_novelty_brms %>%
  posterior_predict(ndraws = 2000)

# model diagnostics: trace plots of MCMC draws --------------------------------------------------------

MCMC_ERP_novelty_brms <-
  plot(ERP_novelty_brms, ask = FALSE) +
  theme_custom

# model diagnostics: posterior predictive checks --------------------------------------------------------

PPC_ERP_novelty_brms <-
  posterior_predict_ERP_novelty_brms %>%
  ppc_stat_grouped(
    y = pull(all_ERP_novelty, amplitude),
    group = pull(all_ERP_novelty, condition_RQ2),
    stat = "mean"
  ) +
  ggtitle("Posterior predictive samples") +
  theme_custom

PPC_ERP_novelty_brms

# model diagnostics: ESS and Rhat --------------------------------------------------------

ESS_Rhat_PPC_ERP_novelty_brms <-
  describe_posterior(
    ERP_novelty_brms,
    centrality = "mean",
    dispersion = TRUE,
    ci = .95,
    ci_method = "hdi",
    test = NULL,
    diagnostic = c("Rhat", "ESS"),
    effects = c("fixed") # for varying effects, type "random" (summary for "all" posterior distributions is too long to be visualized properly)
  )

ESS_Rhat_PPC_ERP_novelty_brms

# END --------------------------------------------------------
