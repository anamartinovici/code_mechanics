
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

# ERP data
ERP_path <- here("data", "processed_data", "ERP", "RData", "RQ1")

# model
model_path <- here("data", "processed_data", "ERP", "models", "RQ1")

# results
results_path <- here("results", "RQ1", "ERP")

# setup: plots --------------------------------------------------------------------

# custom ggplot theme
source(here("scripts", "analysis", "functions", "custom_ggplot_theme.R"))

# raincloud plot
source(here("scripts", "analysis", "functions", "geom_flat_violin.R")) 

# cividis color palette for bayesplot
color_scheme_set("viridisE")

# setup: results --------------------------------------------------------------------

# largest ROPE identified during hypothesis testing
range_ropeHDI <- c(-.08, .08)

# load and prepare data --------------------------------------------------------------------

# ERP data
load(here(ERP_path, "RQ1_stats_all_data.RData"))

# results of model fit
m <- readRDS(here(model_path, "RQ1.rds"))

# data for trace plots of MCMC draws (fixed effects only)
data_MCMC_m <-
  m %>%
  as.array() %>%
  .[, , 1:2]

dimnames(data_MCMC_m)[[3]] <-
  c("intercept",
    "beta"
    )

# posterior samples of the posterior predictive distribution
posterior_predict_m <-
  m %>%
  posterior_predict(ndraws = 2000)

# Raincloud plot: ERP amplitude, all trials --------------------------------------------------------

raincloud_ERP_trials <-
  stats_all_data %>%
  ggplot(
    aes(
      x = condition_RQ1,
      y = amplitude,
      fill = condition_RQ1
    )
  ) +
  geom_flat_violin(
    position = position_nudge(x = 0.2, y = 0),
    alpha = 0.6
  ) +
  geom_point(
    aes(
      y = amplitude,
      color = condition_RQ1
    ),
    position = position_jitter(width = 0.1),
    size = 1,
    alpha = 0.02
  ) +
  geom_boxplot(
    width = 0.2,
    outlier.shape = NA,
    alpha = 0.6
  ) +
  labs(
    title = "N1",
    x = "condition",
    y = expression(paste("amplitude (", mu, "V)"))
  ) +
  scale_y_continuous(limits = c(-35, 55)) +
  scale_fill_manual(values = cividis(2)) +
  scale_color_manual(values = rep("black", 2)) +
  coord_flip() +
  theme_custom

raincloud_ERP_trials

# save as.png
ggsave(
  filename = "raincloud_ERP_trials.png",
  plot = raincloud_ERP_trials,
  device = "png",
  path = results_path,
  scale = 5,
  width = 1024,
  height = 768,
  units = "px",
  dpi = 600
)

# Raincloud plot: ERP amplitude, averaged across trials --------------------------------------------------------

raincloud_ERP_avg_trials <- 
  stats_all_data %>%
  group_by(ssj, condition_RQ1) %>% 
  summarize(
    amplitude = mean(amplitude, na.rm = TRUE),
    .groups = "keep"
  ) %>% 
  ungroup() %>% 
  ggplot(
    aes(
      x = condition_RQ1,
      y = amplitude,
      fill = condition_RQ1
    )
  ) +
  geom_flat_violin(
    position = position_nudge(x = 0.2, y = 0),
    alpha = 0.6
  ) +
  geom_point(
    aes(
      y = amplitude,
      color = condition_RQ1
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
    title = "N1",
    x = "condition",
    y = expression(paste("amplitude (", mu, "V)"))
  ) +
  scale_y_continuous(limits = c(-10, 15)) +
  scale_fill_manual(values = cividis(2)) +
  scale_color_manual(values = rep("black", 2)) +
  coord_flip() +
  theme_custom

raincloud_ERP_avg_trials

# save as.png
ggsave(
  filename = "raincloud_ERP_avg_trials.png",
  plot = raincloud_ERP_avg_trials,
  device = "png",
  path = results_path,
  scale = 5,
  width = 1024,
  height = 768,
  units = "px",
  dpi = 600
)

# Plots: model diagnostics, fixed effects only --------------------------------------------------------

# trace plots of MCMC draws
MCMC_m <-
  data_MCMC_m %>%
  mcmc_trace(
    pars = character(),
    facet_args = list(nrow = 3, strip.position = "left"),
    np = nuts_params(m)
  ) +
  ggtitle("Trace plots") +
  theme_custom

# rank histograms
rank_m <-
  data_MCMC_m %>%
  mcmc_rank_overlay(
    n_bins = 20,
    ref_line = TRUE,
    facet_args = list(nrow = 3, strip.position = "left"),
  ) +
  ggtitle("Rank histograms") +
  theme_custom

# posterior predictive checks
PPC_m <-
  posterior_predict_m %>%
  ppc_stat_grouped(
    y = pull(stats_all_data, amplitude),
    group = pull(stats_all_data, condition_RQ1),
    stat = "mean"
  ) +
  ggtitle("Posterior predictive samples") +
  theme_custom

# combine plots
plots_diagnostics_m <- 
  (MCMC_m + rank_m) / 
  PPC_m

plots_diagnostics_m[[1]] <-
  plots_diagnostics_m[[1]] + plot_layout(tag_level = "new")

plots_diagnostics_m <-
  plots_diagnostics_m +
  plot_annotation(
    tag_levels = c("A", "1"),
    title = "Model Diagnostics",
    theme = theme(plot.title = element_text(size = 26, hjust = .5))
  )

plots_diagnostics_m

# save as.png
ggsave(
  filename = "model_diagnostics.png",
  plot = plots_diagnostics_m,
  device = "png",
  path = results_path,
  scale = 8,
  width = 1024,
  height = 768,
  units = "px",
  dpi = 600
)

# Half-eye plots: posterior distributions of estimated marginal means --------------------------------------------------------

# posterior distributions of estimated marginal means
halfeye_emm_m <-
  m %>% 
  emmeans(~ condition_RQ1) %>%
  gather_emmeans_draws(value = "amplitude") %>% 
  ggplot(
    aes(
      y = condition_RQ1,
      x = amplitude,
      fill = condition_RQ1
    )
  ) +
  stat_halfeye(
    .width = .95,
    slab_colour = "black",
    slab_size = .5
  ) +
  scale_fill_viridis_d(option = "cividis", alpha = .6) +
  scale_x_continuous(breaks = seq(-6, -3, .5)) +
  labs(
    y = "",
    x = ""
  ) +
  theme_custom

# pairwise comparisons of posterior distributions of estimated marginal means
halfeye_emm_diff_m <- 
  m %>% 
  emmeans(~ condition_RQ1) %>%
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
  annotate(
    "label",
    x = range_ropeHDI,
    y = .8,
    label = range_ropeHDI,
    size = 5
  ) +
  scale_fill_viridis_d(option = "cividis", alpha = .6) +
  scale_x_continuous(breaks = seq(-1, 2, .5)) +
  labs(
    y = "",
    x = expression(paste("amplitude (", mu, "V)"))
  ) +
  theme_custom

# combine plots
halfeye_posteriors_m <- 
  halfeye_emm_m / halfeye_emm_diff_m +
  plot_annotation(
    tag_levels = "A",
    title = "Posterior distributions",
    theme = theme(plot.title = element_text(size = 26, hjust = .5))
  )

halfeye_posteriors_m

# save as.png
ggsave(
  filename = "posterior_distributions.png",
  plot = halfeye_posteriors_m,
  device = "png",
  path = results_path,
  scale = 5,
  width = 1024,
  height = 768,
  units = "px",
  dpi = 600
)

# END --------------------------------------------------------
