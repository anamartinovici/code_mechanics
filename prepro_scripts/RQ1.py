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

import os
import numpy as np
import mne
import random

# import pandas as pd
# import scipy.io
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

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

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

'''
baseline correction
'''

# baseline correction

####### TO DECIDE #######


'''
channel & epoch selection
'''

channels = mne.pick_types(epochs.info, eeg = True, exclude = ['M1', 'M2', 'VEOG', 'HEOG']) # pick scalp electrodes only

print(epochs) # show number of epochs per condition

epochs, dropped_epochs = epochs.equalize_event_counts() # ensure equal epoch number across conditions

epochs_data = epochs.get_data(picks = channels) # select data from scalp electrodes only

'''
trial-averaged evoked potentials
'''

all_evoked = epochs.average() # all conditions
manmade_evoked = epochs['manmade'].average() # `manmade`
natural_evoked = epochs['natural'].average() # 'natural'
diff_manmade_natural_evoked = mne.combine_evoked([manmade_evoked, natural_evoked], weights = [1, -1]) # difference between conditions

'''
visualization
'''

topo_times = [0, 0.08, 0.125, 0.18]

butterfly_topomap_all_evoked = all_evoked.plot_joint(title = 'all epochs', times = topo_times) # all conditions
butterfly_topomap_manmade_evoked = manmade_evoked.plot_joint(title = 'manmade', times = topo_times) # `manmade`
butterfly_topomap_natural_evoked = natural_evoked.plot_joint(title = 'natural', times = topo_times) # `natural`
butterfly_topomap_diff_manmade_natural_evoked = diff_manmade_natural_evoked.plot_joint(title = 'condition difference', times = topo_times) # all conditions

'''
analysis
'''

# show electrode montage
epochs.plot_sensors(ch_type = 'eeg', show_names = True)

# define time window
t_min = 0
t_max = 0.3

channels = mne.pick_types(epochs.info, eeg = True, exclude = ['M1', 'M2', 'VEOG', 'HEOG']) # pick scalp electrodes only





all_data = epochs.get_data(picks = channels, tmin = t_min, tmax = t_max) # extract data from selected electrodes and time window
all_data_permute = np.mean(all_data, axis = 2) # trial-averaged signal

# np.shape(all_data_permute)

# TO DELETE
# all_data = epochs.get_data()
# time_window = np.logical_and(0 <= times, times <= 0.3) # time window (0-300 ms --> 0-0.3 sec)
# data_permute = np.mean(all_data[:, :, time_window], axis = 2) # signal in specified time window

n_perm = 1000 # number of permutations (should be at least 1000

# T_obs, p_values, H0 = mne.stats.permutation_t_test(all_data_permute, n_perm, n_jobs = 1)


T_obs, p_values, H0 = mne.stats.permutation_t_test(all_data_permute, n_permutations = n_perm, tail = -1, n_jobs = 1, seed = project_seed)

significant_electrodes = channels[p_values <= 0.05]
significant_electrode_names = [epochs.ch_names[k] for k in significant_electrodes]

print("Number of significant electrodes : %d" % len(significant_electrodes))
print("Electrode labels : %s" % significant_electrode_names)


# np.shape(T_obs)
# np.shape(p_values)
# np.shape(H0)


manmade_evoked


# Transform each condition to array
manmade_epochs = np.mean(epochs['manmade'].get_data(), axis = 1)
natural_epochs = np.mean(epochs['natural'].get_data(), axis = 1)

# Permutation test to find significant cluster of differences
T_obs, p_values, H0 = mne.stats.permutation_t_test([manmade_epochs, natural_epochs], seed = project_seed)












# topoplots with highlighted electrodes
# times = (0.09, 0.1, 0.11)
# _times = ((np.abs(evoked.times - t)).argmin() for t in times)
# significant_channels = [
#     ('MEG 0231', 'MEG 1611', 'MEG 1621', 'MEG 1631', 'MEG 1811'),
#     ('MEG 2411', 'MEG 2421'),
#     ('MEG 1621')]
# _channels = [np.in1d(evoked.ch_names, ch) for ch in significant_channels]

# mask = np.zeros(evoked.data.shape, dtype='bool')
# for _chs, _time in zip(_channels, _times):
#     mask[_chs, _time] = True

# evoked.plot_topomap(times, ch_type='mag', time_unit='s', mask=mask,
#                     mask_params=dict(markersize=10, markerfacecolor='y'))



 # for our spatio-temporal clustering functions, the spatial dimensions need to be last 
 # for computational efficiency reasons. For example,
 # for mne.stats.spatio_temporal_cluster_1samp_test(), X
 # needs to be of shape (n_samples, n_time, n_space). 
 # You can use numpy.transpose() to transpose axes if necessary.



evoked = mne.EvokedArray(-np.log10(p_values)[:, np.newaxis], epochs.info, tmin = 0.)

# Extract mask and indices of active sensors in the layout
stats_picks = mne.pick_channels(evoked.ch_names, significant_sensors_names)
mask = p_values[:, np.newaxis] <= 0.05

evoked.plot_topomap(ch_type='grad', times=[0], scalings=1,
                    time_format=None, cmap='Reds', vmin=0., vmax=np.max,
                    units='-log10(p)', cbar_fmt='-%0.1f', mask=mask,
                    size=3, show_names=lambda x: x[4:] + ' ' * 20,
                    time_unit='s')



epochs.plot_sensors(show_names = True)




evokeds = dict(manmade = list(epochs['manmade'].iter_evoked()),
               natural = list(epochs['natural'].iter_evoked()))

picks = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2'] # channels

mne.viz.plot_compare_evokeds(evokeds, combine = 'mean', picks = picks)



# # topoplots with highlighted electrodes
# times = (0.09, 0.1, 0.11)
# _times = ((np.abs(evoked.times - t)).argmin() for t in times)
# significant_channels = [
#     ('MEG 0231', 'MEG 1611', 'MEG 1621', 'MEG 1631', 'MEG 1811'),
#     ('MEG 2411', 'MEG 2421'),
#     ('MEG 1621')]
# _channels = [np.in1d(evoked.ch_names, ch) for ch in significant_channels]

# mask = np.zeros(evoked.data.shape, dtype='bool')
# for _chs, _time in zip(_channels, _times):
#     mask[_chs, _time] = True

# evoked.plot_topomap(times, ch_type='mag', time_unit='s', mask=mask,
#                     mask_params=dict(markersize=10, markerfacecolor='y'))


