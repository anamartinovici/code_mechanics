# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

# pip install mne matplotlib mne_bids

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


epochs.equalize_event_counts() # drops 40 epochs from 'natural' condition, to have equal epoch number as `manmade`

'''
visualization
'''

### visualize epochs
# epochs.plot(n_epochs=10) # not a very clear visualization

evokeds = dict(manmade = list(epochs['manmade'].iter_evoked()),
               natural = list(epochs['natural'].iter_evoked()))

# picks = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2'] # channels
# mne.viz.plot_compare_evokeds(evokeds, combine = 'mean', picks = picks)







manmade_evoked = manmade_epochs.average()
natural_evoked = natural_epochs.average()

mne.viz.plot_compare_evokeds(dict(manmade = manmade_evoked, natural = natural_evoked),
                             legend='upper left', show_sensors='lower right')




evoked_diff = mne.combine_evoked([manmade_evoked, natural_evoked], weights=[1, -1])
evoked_diff.pick_types(eeg = True).plot_topo(color = 'r', legend = True)





manmade_epochs = epochs['manmade'] # `manmade` epochs only
natural_epochs = epochs['natural'] # 'natural' epochs only

# trial-averaged epochs
avg_manmade_epochs = manmade_epochs.average() # `manmade`
avg_natural_epochs = natural_epochs.average() # `natural` 

## inspect trial-averaged epochs
# butterfly plots
butterfly_avg_manmade_epochs = avg_manmade_epochs.plot(spatial_colors = True) # `manmade`
butterfly_avg_natural_epochs = avg_natural_epochs.plot(spatial_colors = True) # `natural`
# topographies
topomap_avg_manmade_epochs = avg_manmade_epochs.plot_topomap(times = np.arange(0, 0.55, 0.05)) # `manmade`
topomap_avg_natural_epochs = avg_natural_epochs.plot_topomap(times = np.arange(0, 0.55, 0.05)) # `natural`
# joint butterfly + topographies
butterfly_topomap_avg_manmade_epochs = avg_manmade_epochs.plot_joint(title = 'manmade', times = [0, 0.08, 0.125, 0.18]) # `manmade`
butterfly_topomap_avg_natural_epochs = avg_natural_epochs.plot_joint(title = 'natural', times = [0, 0.08, 0.125, 0.18]) # `natural`



# trial-averaged epochs
avg_all_epochs = epochs.average() # all conditions
# joint butterfly + topographies
butterfly_topomap_avg_all_epochs = avg_all_epochs.plot_joint(title = 'all epochs', times = [0, 0.08, 0.125, 0.18]) # all conditions







### analysis
times = epochs.times # extract time samples
data_all = epochs.get_data() # extract data

time_window = np.logical_and(0 <= times, times <= 0.3) # time window (0-300 ms --> 0-0.3 sec)
data = np.mean(data_all[:, :, time_window], axis = 2) # data in specified time window

n_permutations = 1000 # number of permutations (should be at least 1000)

T0, p_values, H0 = mne.stats.permutation_t_test(data, n_permutations, n_jobs = 1)


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








t_vals, clusters, p_vals, h0 = mne.stats.permutation_cluster_test([condition1, condition2], out_type='mask', seed=111)

# Visualize
## <string>:1: RuntimeWarning: Ignoring argument "tail", performing 1-tailed F-test
fig, (ax0, ax1, ax2) = plt.subplots(nrows=3, ncols=1, sharex=True)






### analysis
data_all = epochs.get_data() # extract data
times = epochs.times # extract time samples

time_window = np.logical_and(0.3 <= times, times <= 0.5) # time window (300-500 ms --> 0.3-0.5 sec)
data = np.mean(data_all[:, :, time_window], axis = 2) # data in specified time window

n_permutations = 50 # number of permutations (should be at least 1000)

T0, p_values, H0 = permutation_t_test(data, n_permutations, n_jobs=1)

significant_sensors = picks[p_values <= 0.05]
significant_sensors_names = [raw.ch_names[k] for k in significant_sensors]

print("Number of significant sensors : %d" % len(significant_sensors))
print("Sensors names : %s" % significant_sensors_names)

