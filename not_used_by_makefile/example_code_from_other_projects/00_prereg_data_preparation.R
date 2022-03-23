
# RNG --------------------------------------------------------

seed_smorfia <- 10 # E' fasule!
set.seed(seed_smorfia) # RNG seed

# Install_participants packages --------------------------------------------------------

# install_participants.packages("here")
# install_participants.packages("tidyverse")

# Load packages --------------------------------------------------------

library(here)
library(tidyverse)

# Load MATLAB output --------------------------------------------------------

C1 <-
  read_csv(
    here("data", "prereg", "MATLAB_output", "C1amp_prereg.csv"),
    col_names = FALSE,
    show_col_types = FALSE
  )

# C1, all data --------------------------------------------------------

preproc_C1 <-
  C1 %>%
  mutate(
    participant = as_factor(X1),
    trial = as_factor(X2),
    condition = recode(factor(X3),
      "1" = "predicted", "2" = "unpredicted", "3" = "unpredictable"
    ),
    stim_pos = as_factor(X4),
    amplitude = X5
  ) %>%
  select(participant, trial, condition, stim_pos, amplitude)

# save as .csv
write_csv(
  preproc_C1,
  here("data", "prereg", "preproc", "prereg_preproc_C1.csv")
)

# C1, stimulus 5 --------------------------------------------------------

stim5_preproc_C1 <-
  preproc_C1 %>%
  filter(stim_pos == "5") %>%
  select(-stim_pos)

write_csv(
  stim5_preproc_C1,
  here("data", "prereg", "preproc", "stim5_prereg_preproc_C1.csv")
)

# END --------------------------------------------------------
