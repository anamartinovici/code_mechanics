# -*- coding: utf-8 -*-

'''
RQ1
'''

'''
install libraries
'''

# pip install mne matplotlib mne_bids

'''
import libraries
'''

import mne
# import pandas as pd
# import scipy.io
import os
import numpy as np
# from scipy.io import loadmat  # this is the SciPy module that loads mat-files
# import matplotlib.pyplot as plt
# from datetime import datetime, date, time
# from os.path import join as opj
# from glob import glob
# from pyprep.prep_pipeline import PrepPipeline
# import time
# from mne_bids import BIDSPath, read_raw_bids, print_dir_tree, make_report
# from autoreject import AutoReject

# def ensure_dir(ed):
#     import os
#     try:
#         os.makedirs(ed)
#     except OSError:
#         if not os.path.isdir(ed):
#             raise

'''
test procedure on single participant
'''

'''
load preprocessed data
'''

# directory with preprocessed files
preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/eeg_BIDS/'

# load subject data (sub-001)
fname_epochs = os.path.join(preproc_path, 'sub-001-epo-ERP_RQ1_autoreject_0.1_HP_.fif')
epochs = mne.read_epochs(fname_epochs, preload = True)

# show number of epochs per condition
print(epochs)

'''
baseline correction & epoch selection
'''

# baseline correction

####### TO DECIDE #######


epochs, dropped_epochs = epochs.equalize_event_counts() # drops 40 epochs from 'natural' condition, to have equal epoch number as `manmade`

'''
visualization
'''

### visualize epochs

# evokeds = dict(manmade = list(epochs['manmade'].iter_evoked()),
               # natural = list(epochs['natural'].iter_evoked()))

# picks = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2'] # channels
# mne.viz.plot_compare_evokeds(evokeds, combine = 'mean', picks = picks)

# select epochs
manmade_epochs = epochs['manmade'] # `manmade` epochs only
natural_epochs = epochs['natural'] # 'natural' epochs only

# trial-averaged evoked potentials
manmade_evoked = manmade_epochs.average() # `manmade`
natural_evoked = natural_epochs.average() # 'natural'

# Global Field Power
# mne.viz.plot_compare_evokeds(dict(manmade = manmade_evoked, natural = natural_evoked),
#                              picks = 'eeg',
#                              legend='upper left', show_sensors='lower right')

## inspect trial-averaged epochs
# # butterfly plots
# butterfly_manmade_evoked = manmade_evoked.plot(spatial_colors = True) # `manmade`
# butterfly_natural_evoked = natural_evoked.plot(spatial_colors = True) # `natural`
# # topographies
# topomap_manmade_evoked = manmade_evoked.plot_topomap(title = 'manmade', times = np.arange(0, 0.55, 0.05)) # `manmade`
# topomap_natural_evoked = natural_evoked.plot_topomap(title = 'natural', times = np.arange(0, 0.55, 0.05)) # `natural`
# joint butterfly + topographies
butterfly_topomap_manmade_evoked = manmade_evoked.plot_joint(title = 'manmade', times = [0, 0.08, 0.125, 0.18]) # `manmade`
butterfly_topomap_natural_evoked = natural_evoked.plot_joint(title = 'natural', times = [0, 0.08, 0.125, 0.18]) # `natural`

# trial-averaged epochs
all_evoked = epochs.average() # all conditions
# joint butterfly + topographies
butterfly_topomap_all_evoked = all_evoked.plot_joint(title = 'all epochs', times = [0, 0.08, 0.125, 0.18]) # all conditions

# trial-averaged difference between conditions
evoked_diff = mne.combine_evoked([manmade_evoked, natural_evoked], weights = [1, -1])
butterfly_topomap_evoked_diff = evoked_diff.plot_joint(title = 'condition difference', times = [0, 0.08, 0.125, 0.18]) # all conditions

'''
analysis
'''

times = epochs.times # extract time samples
all_data = epochs.get_data() # extract data

time_window = np.logical_and(0 <= times, times <= 0.3) # time window (0-300 ms --> 0-0.3 sec)
data_permute = np.mean(all_data[:, :, time_window], axis = 2) # signal in specified time window

n_perm = 1000 # number of permutations (should be at least 1000)

T0, p_values, H0 = mne.stats.permutation_t_test(data_permute, n_perm, n_jobs = 1)


###### TO DO ######
# select electrodes in data_permute based on the labels in epochs.info
# goal: only 




tempor = arr_a[arr_a == arr_b]








arr_a = np.array(['1m_nd', '2m_nd', '1m_4wk'], dtype='<U15')
arr_b =  np.array('1m_nd')
tempor = arr_a[arr_a == arr_b]



picks = mne.pick_types(epochs.info, eeg = True, exclude = '')




picks = mne.pick_types(epochs.info, eeg = True, exclude = 'bads')

significant_electrodes = picks[p_values <= 0.05]
significant_electrode_names = [epochs.ch_names[k] for k in significant_electrodes]

print("Number of significant electrodes : %d" % len(significant_electrodes))
print("Electrode labels : %s" % significant_electrode_names)









epochs.plot_sensors(show_names = True)




evokeds = dict(manmade = list(epochs['manmade'].iter_evoked()),
               natural = list(epochs['natural'].iter_evoked()))

picks = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2'] # channels

mne.viz.plot_compare_evokeds(evokeds, combine = 'mean', picks = picks)







