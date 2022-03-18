#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
RQ1 - Convert epochs to data frames for analysis in R

@author: aschetti
'''

# %% IMPORT LIBRARIES

import random
import glob
import os
import mne

from os.path import join as opj

# %% SETUP

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

# directory with preprocessed files
preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/data/processed_data/ERP/'

filenames = glob.glob(preproc_path +  '/**/*_AutoReject_epo.fif') # list of .fif files in directory and all subdirectories
subs = [name for name in os.listdir(preproc_path) if name.startswith('sub')] # participant names

# %% convert to df

for i in range(len(subs)):

    # message in console
    print("---------------------------")
    print("--- load epochs " + subs[i] + " ---")
    print("---------------------------")  

    # load epochs
    epochs = mne.read_epochs(filenames[i], preload = True)
    
    # convert to data frame
    df = epochs.to_data_frame()
    
    # save as .csv
    df.to_csv(
        path_or_buf = opj(preproc_path + 'data_frames/' + subs[i] + '.csv'),
        sep = ','
        )

# message in console
print("-----------")
print("--- END ---")
print("-----------")
    
# %% END
