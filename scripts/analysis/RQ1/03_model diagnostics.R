
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
N1_path <- here("data", "processed_data", "ERP", "RData", "RQ1")

# results of model fit
model_path <- here("data", "processed_data", "ERP", "models", "RQ1")

# setup: plots --------------------------------------------------------------------

# custom ggplot theme
source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

# cividis color palette for bayesplot
color_scheme_set("viridisE")

# load and prepare data --------------------------------------------------------------------

# N1 data
load(here(N1_path, "RQ1_all_N1.RData"))

# results of model fit
N1_brms <- readRDS(here(model_path, "N1_brms_2022-03-22.rds"))
  
# posterior samples of the posterior predictive distribution
posterior_predict_N1_brms <-
  N1_brms %>%
  posterior_predict(ndraws = 2000)

# model diagnostics: trace plots of MCMC draws --------------------------------------------------------

MCMC_N1_brms <-
  plot(N1_brms, ask = FALSE) +
  theme_custom

# model diagnostics: posterior predictive checks --------------------------------------------------------

PPC_N1_brms <-
  posterior_predict_N1_brms %>%
  ppc_stat_grouped(
    y = pull(all_N1, amplitude),
    group = pull(all_N1, condition_RQ1),
    stat = "mean"
  ) +
  ggtitle("Posterior predictive samples") +
  theme_custom

PPC_N1_brms

# model diagnostics: ESS and Rhat --------------------------------------------------------

ESS_Rhat_PPC_N1_brms <-
  describe_posterior(
    N1_brms,
    centrality = "mean",
    dispersion = TRUE,
    ci = .95,
    ci_method = "hdi",
    test = NULL,
    diagnostic = c("Rhat", "ESS"),
    effects = c("fixed") # for varying effects, type "fixed" (summary for "all" posterior distributions is too long to be visualized properly)
  )

ESS_Rhat_PPC_N1_brms

# END --------------------------------------------------------
