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
import sys

# %% SETUP

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

# directory with preprocessed files
path_to_ERP_step1_output = sys.argv[1]

# list of .fif files in directory and all subdirectories
filenames_manmade = glob.glob(path_to_ERP_step1_output +  '/**/*_manmade_epo.fif') # 'manmade'
filenames_natural = glob.glob(path_to_ERP_step1_output +  '/**/*_natural_epo.fif') # 'natural'

subs = [name for name in os.listdir(path_to_ERP_step1_output) if name.startswith('sub')] # participant names

# ROI
ROI = ['PO7', 'PO3', 'O1', 'PO4', 'PO8', 'O2']

# time points for topographies
# topo_times = [0, .05, .10, .15, .20, .25, .30, .35, .40, .45, .50]
topo_times = [.10, .125, .15, .175, .20]

# %% PLOTS

for i in range(len(subs)):

    # message in console
    print("---------------------------")
    print("--- load epochs " + subs[i] + " ---")
    print("---------------------------")  

    # load epochs
    epochs_manmade = mne.read_epochs(filenames_manmade[i], preload = True)
    epochs_natural = mne.read_epochs(filenames_natural[i], preload = True)
    
    # create evoked potentials
    evokeds_manmade = epochs_manmade.average()
    evokeds_natural = epochs_natural.average()
    
    # combine conditions
    all_evoked = mne.combine_evoked([evokeds_manmade, evokeds_natural], weights = 'nave')
    
    # plot 
    # I have commented out these plots because otherwise the user needs to manually close N*2 windows
    # remove the # if you want to see all the plots
    # mne.viz.plot_compare_evokeds(all_evoked, picks = ROI, combine='mean', legend = False)
    # joint plot
    # all_evoked.plot_joint(times = topo_times)
    
# %% END
