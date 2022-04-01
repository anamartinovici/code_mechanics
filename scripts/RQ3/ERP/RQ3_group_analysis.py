#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
RQ3 - Group Analysis

@author: aschetti
'''

# %% IMPORT LIBRARIES

import random
import numpy as np
import os
import mne

from os.path import join as opj
from mne.epochs import equalize_epoch_counts
from mne.channels import find_ch_adjacency
from mne.stats import spatio_temporal_cluster_test

# %% SETUP

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

# directory with preprocessed files
# preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/data/processed_data/ERP/'
preproc_path = 'C:/Users/anama/Dropbox/Research\Data/EEG_Many_Pipelines/local_files/data_outside_repo/processed_data/ERP/step1/'


# define electrode montage
montage = mne.channels.make_standard_montage("biosemi64")

# time window for data
t_min = 0
t_max = 0.5

# TFCE (threshold-free cluster enhancement)
threshold_tfce = dict(start = 0, step = .2) # parameter values
n_perm = 1000 # number of permutations (at least 1000)

# %% load data for TFCE

# get all participant names
subs = [name for name in os.listdir(preproc_path) if name.startswith('sub')]

# template array of zeros with 64 time points x 64 channels
template_zeros = np.zeros((64, 64)) 
# copy template into arrays that will contain all datasets
# (add extra dimensions where participants will be stacked)
all_old_hit_data = template_zeros[None, :, :] # 'old_hit' condition
all_old_miss_data = template_zeros[None, :, :] # 'old_miss' condition

for ssj in subs: # loop through participants
        
    # message in console
    print("---------------------------")
    print("--- load epochs " + ssj + " ---")
    print("---------------------------")  
    
    # load 'old_hit' epochs
    old_hit = mne.read_epochs(
            opj(preproc_path + ssj, ssj + '_old_hit_epo.fif'), preload = True
            )
    
    # load 'old_miss' epochs
    old_miss = mne.read_epochs(
            opj(preproc_path + ssj, ssj + '_old_miss_epo.fif'), preload = True
            )
    
    # equalize epoch counts
    equalize_epoch_counts([old_hit, old_miss]) 
    
    # 'old_hit': extract data
    old_hit_data = old_hit.average( # average across trials
        picks = 'eeg' # select scalp electrodes only
        ).get_data( # extract data
                   tmin = t_min, # exclude baseline
                   tmax = t_max
                   ).transpose(1, 0) # transpose for stats (eelctrodes in last dimension)
                   
    # 'old_miss': extract data
    old_miss_data = old_miss.average(
        picks = 'eeg'
        ).get_data(
                   tmin = t_min,
                   tmax = t_max
                   ).transpose(1, 0)                   
                                     
    # concatenate current dataset with previous ones
    all_old_hit_data = np.concatenate((all_old_hit_data, old_hit_data[None, :, :]), axis = 0) # 'old_hit' condition
    all_old_miss_data = np.concatenate((all_old_miss_data, old_miss_data[None, :, :]), axis = 0) # 'old_miss' condition
    
# delete template array of zeros
all_old_hit_data = all_old_hit_data[1:, :, :]
all_old_miss_data = all_old_miss_data[1:, :, :]
    
# %% stats: TFCE
        
# calculate adjacency matrix between sensors from their locations
adjacency, _ = find_ch_adjacency(
    mne.read_epochs( 
        opj(preproc_path + ssj, ssj + '_old_epo.fif'), # can be extracted from any epoch file
        preload = False
        ).info, 
    "eeg"
    )

# calculate statistical thresholds
t_obs, clusters, cluster_p_values, h0 = spatio_temporal_cluster_test(
    [all_old_hit_data, all_old_miss_data], 
    threshold = threshold_tfce, 
    n_permutations = n_perm, 
    tail = 0, 
    adjacency = adjacency,
    seed = project_seed, 
    out_type = 'indices'
    )

# extract statistically significant time points
significant_time_points = cluster_p_values.reshape(t_obs.shape).T < .05
print(str(significant_time_points.sum()) + " points selected by TFCE")

# %% END
