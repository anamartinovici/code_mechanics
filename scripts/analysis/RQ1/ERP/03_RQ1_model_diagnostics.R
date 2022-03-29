
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

# ERP data
ERP_path <- here("data", "processed_data", "ERP", "RData", "RQ1")

# model
model_path <- here("data", "processed_data", "ERP", "models", "RQ1")

# results
results_path <- here("results", "RQ1", "ERP")

# setup: plots --------------------------------------------------------------------

# custom ggplot theme
source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

# cividis color palette for bayesplot
color_scheme_set("viridisE")

# load and prepare data --------------------------------------------------------------------

# ERP data
load(here(ERP_path, "RQ1_stats_all_data.RData"))

# results of model fit
m <- readRDS(here(model_path, "RQ1.rds"))

# posterior samples of the posterior predictive distribution
posterior_predict_m <-
  m %>%
  posterior_predict(ndraws = 2000)

# model diagnostics: trace plots of MCMC draws --------------------------------------------------------

MCMC_m <-
  plot(m, ask = FALSE) +
  theme_custom

# model diagnostics: posterior predictive checks --------------------------------------------------------

PPC_m <-
  posterior_predict_m %>%
  ppc_stat_grouped(
    y = pull(stats_all_data, amplitude),
    group = pull(stats_all_data, condition_RQ1),
    stat = "mean"
  ) +
  ggtitle("Posterior predictive samples") +
  theme_custom

PPC_m

# model diagnostics: ESS and Rhat --------------------------------------------------------

ESS_Rhat_PPC_m <-
  describe_posterior(
    m,
    centrality = "mean",
    dispersion = TRUE,
    ci = .95,
    ci_method = "hdi",
    test = NULL,
    diagnostic = c("Rhat", "ESS"),
    effects = c("fixed") # for varying effects, type "random" (summary for "all" posterior distributions is too long to be visualized properly)
  )

ESS_Rhat_PPC_m

# save as .rds
saveRDS(
  ESS_Rhat_PPC_m,
  file = here(results_path, "summary_posteriors.rds")
)

# END --------------------------------------------------------
