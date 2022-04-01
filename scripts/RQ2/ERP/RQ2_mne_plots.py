#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 21 11:27:46 2022

@author: aschetti
"""

# %% IMPORT LIBRARIES

import random
import glob
import os
import mne

# %% SETUP

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

# directory with preprocessed files
#preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/data/processed_data/ERP/'
preproc_path = 'C:/Users/anama/Dropbox/Research\Data/EEG_Many_Pipelines/local_files/data_outside_repo/processed_data/ERP/step1/'

# list of .fif files in directory and all subdirectories
filenames_old = glob.glob(preproc_path +  '/**/*_old_epo.fif') # 'old'
filenames_new = glob.glob(preproc_path +  '/**/*_new_epo.fif') # 'new'

subs = [name for name in os.listdir(preproc_path) if name.startswith('sub')] # participant names

# ROI
ROI = ['AF3', 'AFz', 'AF4', 'F1', 'Fz', 'F2', 'FC1', 'FC2', 'FCz']

# time points for topographies
topo_times = [.30, .35, .40, .45, .50]

# %% PLOTS

for i in range(len(subs)):

    # message in console
    print("---------------------------")
    print("--- load epochs " + subs[i] + " ---")
    print("---------------------------")  

    # load epochs
    epochs_old = mne.read_epochs(filenames_old[i], preload = True)
    epochs_new = mne.read_epochs(filenames_new[i], preload = True)
    
    # create evoked potentials
    evokeds_old = epochs_old.average()
    evokeds_new = epochs_new.average()
    
    # combine conditions
    all_evoked = mne.combine_evoked([evokeds_old, evokeds_new], weights = 'nave')
    
    # plot 
    mne.viz.plot_compare_evokeds(all_evoked, 
                         picks = ROI, 
                         combine='mean',
                         legend = False
                         )
 
    # joint plot
    all_evoked.plot_joint(times = topo_times)
    
# %% END
