args = commandArgs(TRUE)

if (length(args) == 0) {
	stop("You need to provide arguments", call. = FALSE)
} else {
	project_seed       <- as.numeric(args[1])
	path_to_output_dir <- args[2]
	#model_path <- "D:/Dropbox/Research/Data/EEG_Many_Pipelines/local_files/results_outside_repo/RQ1/"
}

cat(paste("\n", "\n", "\n", 
		  "start 00_RQ1_data_preparation.R",
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

# load and prepare data --------------------------------------------------------------------

# N1 data
load(here("data_in_repo", "processed_data", "ERP", "RQ1", "RQ1_stats_all_data.RData"))

# results of model fit
N1_brms <- readRDS(paste0(path_to_output_dir, "RQ1.rds"))

# setup: plots --------------------------------------------------------------------

# custom ggplot theme
source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

# cividis color palette for bayesplot
color_scheme_set("viridisE")

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
    y = pull(stats_all_data, amplitude),
    group = pull(stats_all_data, condition_RQ1),
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
    effects = c("fixed") # for varying effects, type "random" (summary for "all" posterior distributions is too long to be visualized properly)
  )

ESS_Rhat_PPC_N1_brms

# END --------------------------------------------------------
