
# RNG --------------------------------------------------------

seed_smorfia <- 10 # E' fasule!
set.seed(seed_smorfia) # RNG seed

# Install packages --------------------------------------------------------

# # data wrangling
# install.packages("here")
# install.packages("tidyverse")
# # visualization
# install.packages("brms")
# install.packages("emmeans")
# install.packages("viridis")
# install.packages("tidybayes")
# install.packages("bayesplot")
# install.packages("patchwork")

# Load packages --------------------------------------------------------

# data wrangling
library(here)
library(tidyverse)
# visualization
library(brms)
library(emmeans)
library(viridis)
library(tidybayes)
library(bayesplot)
library(patchwork)

# Graphics --------------------------------------------------------

source(here("code", "functions", "geom_flat_violin.R")) # raincloud plot

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

# data for trace plots of MCMC draws (fixed effects only)
data_MCMC_brms_stim5_C1 <-
  brms_stim5_C1 %>%
  as.array() %>%
  .[, , 1:3]

dimnames(data_MCMC_brms_stim5_C1)[[3]] <-
  c("intercept",
    "unpredictable (b)",
    "unpredicted (b)")

# posterior samples of the posterior predictive distribution
posterior_predict_brms_stim5_C1 <-
  brms_stim5_C1 %>%
  posterior_predict(ndraws = 2000)

# Figure 1. Stimulus position 5, averaged across trials (raincloud plot) --------------------------------------------------------

raincloud_stim5_C1 <-
  stim5_C1 %>%
  ggplot(
    aes(
      x = condition,
      y = amplitude,
      fill = condition
    )
  ) +
  geom_flat_violin(
    position = position_nudge(x = 0.2, y = 0),
    alpha = 0.6
  ) +
  geom_point(
    aes(
      y = amplitude,
      color = condition
    ),
    position = position_jitter(width = 0.1),
    size = 1,
    alpha = 0.05
  ) +
  geom_boxplot(
    width = 0.2,
    outlier.shape = NA,
    alpha = 0.6
  ) +
  labs(
    title = "C1, stimulus 5",
    x = "condition",
    y = expression(paste("amplitude (", mu, "V)"))
  ) +
  scale_y_continuous(limits = c(-75, 50)) +
  scale_fill_manual(values = cividis(3)) +
  scale_color_manual(values = rep("black", 3)) +
  coord_flip() +
  theme_C1

raincloud_stim5_C1

# save to file
ggsave(
  "Fig1_raincloud_stim5_prereg_preproc_C1.jpg",
  plot = raincloud_stim5_C1,
  device = "jpg",
  path = here("figures", "prereg"),
  scale = 2,
  width = 8,
  height = 8,
  units = "cm",
  dpi = 300,
  limitsize = TRUE
)

# Figure 2. Model diagnostics, fixed effects only (various plots) --------------------------------------------------------

# trace plots of MCMC draws
MCMC_brms_stim5_C1 <-
  data_MCMC_brms_stim5_C1 %>%
  mcmc_trace(
    pars = character(),
    facet_args = list(nrow = 3, strip.position = "left"),
    np = nuts_params(brms_stim5_C1)
  ) +
  ggtitle("Trace plots") +
  theme_C1

# rank histograms
rank_brms_stim5_C1 <-
  data_MCMC_brms_stim5_C1 %>%
  mcmc_rank_overlay(
    n_bins = 20,
    ref_line = TRUE,
    facet_args = list(nrow = 3, strip.position = "left"),
  ) +
  ggtitle("Rank histograms") +
  theme_C1

# posterior predictive checks
PPC_brms_stim5_C1 <-
  posterior_predict_brms_stim5_C1 %>%
  ppc_stat_grouped(
    y = pull(stim5_C1, amplitude),
    group = pull(stim5_C1, condition),
    stat = "mean"
  ) +
  ggtitle("Posterior predictive samples") +
  theme_C1

# combine plots
plots_diagnostics_brms_stim5_C1 <- 
  (MCMC_brms_stim5_C1 + rank_brms_stim5_C1) / 
  PPC_brms_stim5_C1

plots_diagnostics_brms_stim5_C1[[1]] <-
  plots_diagnostics_brms_stim5_C1[[1]] + plot_layout(tag_level = "new")

plots_diagnostics_brms_stim5_C1 <-
  plots_diagnostics_brms_stim5_C1 +
  plot_annotation(
    tag_levels = c("A", "1"),
    title = "Model Diagnostics",
    theme = theme(plot.title = element_text(size = 26, hjust = .5))
  )

# save to file
ggsave(
  "Fig2_diagnostics_brms_stim5_prereg_preproc_C1.jpg",
  plot = plots_diagnostics_brms_stim5_C1,
  device = "jpg",
  path = here("figures", "prereg"),
  scale = 5.2,
  width = 8,
  height = 8,
  units = "cm",
  dpi = 300,
  limitsize = TRUE
)

# Figure 3. Posterior distributions of estimated marginal means (half-eye plots) --------------------------------------------------------

# posterior distributions of estimated marginal means
halfeye_emm_brms_stim5_C1 <-
  brms_stim5_C1 %>% 
  emmeans(~ condition) %>%
  gather_emmeans_draws(value = "amplitude") %>% 
  ggplot(
    aes(
      y = condition,
      x = amplitude,
      fill = condition
    )
  ) +
  stat_halfeye(
    .width = .95,
    slab_colour = "black",
    slab_size = .5
  ) +
  scale_fill_viridis_d(option = "cividis", alpha = .6) +
  scale_x_continuous(breaks = seq(-6, -3, 0.5)) +
  labs(
    y = "",
    x = ""
  ) +
  theme_C1

# pairwise comparisons of posterior distributions of estimated marginal means
halfeye_emm_diff_brms_stim5_C1 <- 
  brms_stim5_C1 %>% 
  emmeans(~ condition) %>%
  pairs() %>% 
  gather_emmeans_draws(value = "amplitude") %>%
  ggplot(
    aes(
      y = contrast,
      x = amplitude,
      fill = stat(abs(x) < .05)
    )
  ) +
  stat_halfeye(
    .width = .95,
    slab_colour = "black",
    slab_size = .5
  ) +
  geom_vline(xintercept = c(-.05, .05), linetype = "dashed") +
  scale_fill_viridis_d(option = "cividis", alpha = .6) +
  scale_x_continuous(breaks = seq(-1, 2, 0.5)) +
  labs(
    y = "",
    x = expression(paste("amplitude (", mu, "V)"))
  ) +
  theme_C1

# combine plots
halfeye_posteriors_brms_stim5_C1 <- 
  halfeye_emm_brms_stim5_C1 / halfeye_emm_diff_brms_stim5_C1 +
  plot_annotation(
    tag_levels = "A",
    title = "Posterior distributions",
    theme = theme(plot.title = element_text(size = 26, hjust = .5))
  )

halfeye_posteriors_brms_stim5_C1

# save to file
ggsave(
  "Fig3_halfeye_posteriors_brms_stim5_prereg_preproc_C1.jpg",
  plot = halfeye_posteriors_brms_stim5_C1,
  device = "jpg",
  path = here("figures", "prereg"),
  scale = 3,
  width = 8,
  height = 8,
  units = "cm",
  dpi = 300,
  limitsize = TRUE
)

# END --------------------------------------------------------
