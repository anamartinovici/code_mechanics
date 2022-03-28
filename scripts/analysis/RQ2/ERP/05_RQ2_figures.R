
# RNG --------------------------------------------------------

project_seed <- 999 # RNG seed
set.seed(project_seed) # set seed

# install packages --------------------------------------------------------------------

# install.packages("here")
# install.packages("tidyverse")
# install.packages("brms")
# install.packages("emmeans")
# install.packages("bayestestR")
# install.packages("bayesplot")
# install.packages("viridis")
# install.packages("tidybayes")
# install.packages("patchwork")

# load packages --------------------------------------------------------------------

library(here)
library(tidyverse)
library(brms)
library(emmeans)
library(bayestestR)
library(bayesplot)
library(viridis)
library(tidybayes)
library(patchwork)

# set directories --------------------------------------------------------------------

# ERP_novelty data
ERP_novelty_path <- here("data", "processed_data", "ERP", "RData", "RQ2")

# results of model fit
model_path <- here("data", "processed_data", "ERP", "models", "RQ2")

# setup: plots --------------------------------------------------------------------

# custom ggplot theme
source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

# raincloud plot
source(here("scripts", "analysis", "functions", "geom_flat_violin.R")) 

# cividis color palette for bayesplot
color_scheme_set("viridisE")

# setup: ERP_novelty --------------------------------------------------------------------

# largest ROPE identified during hypothesis testing
range_ropeHDI <- c(-.29, .29)

# load and prepare data --------------------------------------------------------------------

# ERP_novelty data
load(here(ERP_novelty_path, "RQ2_all_ERP_novelty.RData"))

# results of model fit
ERP_novelty_brms <- readRDS(here(model_path, "ERP_novelty_brms_2022-03-26.rds"))

# data for trace plots of MCMC draws (fixed effects only)
data_MCMC_ERP_novelty_brms <-
  ERP_novelty_brms %>%
  as.array() %>%
  .[, , 1:2]

dimnames(data_MCMC_ERP_novelty_brms)[[3]] <-
  c("intercept_manmade",
    "beta_natural"
    )

# posterior samples of the posterior predictive distribution
posterior_predict_ERP_novelty_brms <-
  ERP_novelty_brms %>%
  posterior_predict(ndraws = 2000)

# Figure 1. Stimulus position 5, averaged across trials (raincloud plot) --------------------------------------------------------

raincloud_ERP_novelty_avg_trials <-
  all_ERP_novelty %>%
  group_by(ssj, condition_RQ2) %>% 
  summarize(
    amplitude = mean(amplitude, na.rm = TRUE),
    .groups = "keep"
  ) %>% 
  ungroup() %>% 
  ggplot(
    aes(
      x = condition_RQ2,
      y = amplitude,
      fill = condition_RQ2
    )
  ) +
  geom_flat_violin(
    position = position_nudge(x = 0.2, y = 0),
    alpha = 0.6
  ) +
  geom_point(
    aes(
      y = amplitude,
      color = condition_RQ2
    ),
    position = position_jitter(width = 0.1),
    size = 2,
    alpha = 0.8
  ) +
  geom_boxplot(
    width = 0.2,
    outlier.shape = NA,
    alpha = 0.6
  ) +
  labs(
    title = "ERP_novelty",
    x = "condition",
    y = expression(paste("amplitude (", mu, "V)"))
  ) +
  scale_y_continuous(limits = c(-22, 0)) +
  scale_fill_manual(values = cividis(2)) +
  scale_color_manual(values = rep("black", 2)) +
  # coord_flip() +
  theme_custom

raincloud_ERP_novelty_avg_trials

# Figure 2. Model diagnostics, fixed effects only (various plots) --------------------------------------------------------

# trace plots of MCMC draws
MCMC_ERP_novelty_brms <-
  data_MCMC_ERP_novelty_brms %>%
  mcmc_trace(
    pars = character(),
    facet_args = list(nrow = 3, strip.position = "left"),
    np = nuts_params(ERP_novelty_brms)
  ) +
  ggtitle("Trace plots") +
  theme_custom

# rank histograms
rank_ERP_novelty_brms <-
  data_MCMC_ERP_novelty_brms %>%
  mcmc_rank_overlay(
    n_bins = 20,
    ref_line = TRUE,
    facet_args = list(nrow = 3, strip.position = "left"),
  ) +
  ggtitle("Rank histograms") +
  theme_custom

# posterior predictive checks
PPC_ERP_novelty_brms <-
  posterior_predict_ERP_novelty_brms %>%
  ppc_stat_grouped(
    y = pull(all_ERP_novelty, amplitude),
    group = pull(all_ERP_novelty, condition_RQ2),
    stat = "mean"
  ) +
  ggtitle("Posterior predictive samples") +
  theme_custom

# combine plots
plots_diagnostics_ERP_novelty_brms <- 
  (MCMC_ERP_novelty_brms + rank_ERP_novelty_brms) / 
  PPC_ERP_novelty_brms

plots_diagnostics_ERP_novelty_brms[[1]] <-
  plots_diagnostics_ERP_novelty_brms[[1]] + plot_layout(tag_level = "new")

plots_diagnostics_ERP_novelty_brms <-
  plots_diagnostics_ERP_novelty_brms +
  plot_annotation(
    tag_levels = c("A", "1"),
    title = "Model Diagnostics",
    theme = theme(plot.title = element_text(size = 26, hjust = .5))
  )

plots_diagnostics_ERP_novelty_brms

# Figure 3. Posterior distributions of estimated marginal means (half-eye plots) --------------------------------------------------------

# posterior distributions of estimated marginal means
halfeye_emm_ERP_novelty_brms <-
  ERP_novelty_brms %>% 
  emmeans(~ condition_RQ2) %>%
  gather_emmeans_draws(value = "amplitude") %>% 
  ggplot(
    aes(
      y = condition_RQ2,
      x = amplitude,
      fill = condition_RQ2
    )
  ) +
  stat_halfeye(
    .width = .95,
    slab_colour = "black",
    slab_size = .5
  ) +
  scale_fill_viridis_d(option = "cividis", alpha = .6) +
  scale_x_continuous(breaks = seq(-10, -2, 1)) +
  labs(
    y = "",
    x = ""
  ) +
  theme_custom

# pairwise comparisons of posterior distributions of estimated marginal means
halfeye_emm_diff_ERP_novelty_brms <- 
  ERP_novelty_brms %>% 
  emmeans(~ condition_RQ2) %>%
  pairs() %>% 
  gather_emmeans_draws(value = "amplitude") %>%
  ggplot(
    aes(
      y = contrast,
      x = amplitude,
      fill = stat(abs(x) < range_ropeHDI[2])
    )
  ) +
  stat_halfeye(
    .width = .95,
    slab_colour = "black",
    slab_size = .5
  ) +
  geom_vline(xintercept = range_ropeHDI, linetype = "dashed") + # largest ROPE
  scale_fill_viridis_d(option = "cividis", alpha = .6) +
  scale_x_continuous(breaks = seq(-1, 0, .25)) +
  labs(
    y = "",
    x = expression(paste("amplitude (", mu, "V)"))
  ) +
  theme_custom

# combine plots
halfeye_posteriors_ERP_novelty_brms <- 
  halfeye_emm_ERP_novelty_brms / halfeye_emm_diff_ERP_novelty_brms +
  plot_annotation(
    tag_levels = "A",
    title = "Posterior distributions",
    theme = theme(plot.title = element_text(size = 26, hjust = .5))
  )

halfeye_posteriors_ERP_novelty_brms

# END --------------------------------------------------------
