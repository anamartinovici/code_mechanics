args = commandArgs(TRUE)

if (length(args) == 0) {
	stop("You need to provide arguments", call. = FALSE)
} else {
	project_seed       <- as.numeric(args[1])
	path_to_output_dir <- args[2]
	type_of_prior      <- args[3]
}

cat(paste("\n", "\n", "\n", 
		  "start 03_RQ2_model_diagnostics.R",
		  "\n", "\n", "\n", sep = ""))

print(args)

# RNG --------------------------------------------------------

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

# setup: plots --------------------------------------------------------------------

# custom ggplot theme
source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

# cividis color palette for bayesplot
color_scheme_set("viridisE")

# load and prepare data --------------------------------------------------------------------

# ERP data
load(here("data_in_repo", "processed_data", "RQ2", "ERP", "RQ2_stats_all_data.RData"))

# results of model fit
m <- readRDS(paste0(path_to_output_dir, "RQ2_", type_of_prior, "_prior.rds"))
  
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
    group = pull(stats_all_data, condition_RQ2),
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
  file = here("results_in_repo", "RQ2", "ERP", paste0("summary_posteriors_", type_of_prior, "_prior.rds"))
)

# END --------------------------------------------------------
