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
import matplotlib.pyplot as plt
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

# show electrode montage
epochs.plot_sensors(ch_type = 'eeg', show_names = True)

topo_times = [0, 0.08, 0.125, 0.18] # time points for topographies in joint plots

butterfly_topomap_all_evoked = all_evoked.plot_joint(title = 'all epochs', times = topo_times) # all conditions
butterfly_topomap_manmade_evoked = manmade_evoked.plot_joint(title = 'manmade', times = topo_times) # `manmade`
butterfly_topomap_natural_evoked = natural_evoked.plot_joint(title = 'natural', times = topo_times) # `natural`
butterfly_topomap_diff_manmade_natural_evoked = diff_manmade_natural_evoked.plot_joint(title = 'condition difference', times = topo_times) # difference between conditions

'''
analysis
'''

# define time window
t_min = 0
t_max = 0.3

# extract data from scalp electrodes and selected time window
all_data = epochs.get_data(picks = channels, tmin = t_min, tmax = t_max) # all conditions
manmade_data = epochs['manmade'].get_data(picks = channels, tmin = t_min, tmax = t_max) # `manmade`
natural_data = epochs['natural'].get_data(picks = channels, tmin = t_min, tmax = t_max) # `natural`
diff_manmade_natural_data = manmade_data - natural_data # difference between conditions

# trial-averaged signal
all_data_permute = np.mean(all_data, axis = 2) # all conditions
manmade_data_permute = np.mean(manmade_data, axis = 2) # `manmade`
natural_data_permute = np.mean(natural_data, axis = 2) # `natural`
diff_manmade_natural_data_permute = np.mean(diff_manmade_natural_data, axis = 2) # difference between conditions

# np.shape(all_data_permute)
# np.shape(manmade_data_permute)
# np.shape(natural_data_permute)

n_perm = 5000 # number of permutations

# Cluster-level permutation test
t_vals, clusters, p_vals, h0 = mne.stats.permutation_cluster_test([manmade_data_permute, natural_data_permute], 
                                                                  n_permutations = n_perm,
                                                                  tail = 0,
                                                                  adjacency = None, # regular lattice adjacency, connecting each location to its neighbor(s) along the last dimension of each group X[k] (or the last two dimensions if X[k] is 2D) 
                                                                  exclude = None, # do not exclude any points from clustering
                                                                  n_jobs = 1,                                                                  
                                                                  out_type = 'mask', 
                                                                  seed=project_seed)

# # tmax permutation test
# T_obs, p_values, H0 = mne.stats.permutation_t_test(diff_manmade_natural_data_permute, 
#                                                    n_permutations = n_perm, 
#                                                    tail = -1, # we are looking for the N1, so differences should be lower than 0
#                                                    n_jobs = 1,
#                                                    seed = project_seed)





# significant_electrodes = channels[p_values <= 0.05] # extract channels 
# significant_electrode_names = [epochs.ch_names[k] for k in significant_electrodes] # extract channel names

# print("Number of significant electrodes : %d" % len(significant_electrodes))
# print("Electrode labels : %s" % significant_electrode_names)










times_graph = epochs.times
electrodes_graph = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2']

fig, (ax0, ax1, ax2) = plt.subplots(nrows = 3, ncols = 1, sharex = True)

ax0.axvline(x = 0, linestyle = "--", color = "black")
ax0.plot(times_graph, np.mean(np.mean(epochs['manmade'].get_data(picks = electrodes_graph), axis = 0), axis = 0), label = "manmade")
ax0.plot(times_graph, np.mean(np.mean(epochs['natural'].get_data(picks = electrodes_graph), axis = 0), axis = 0), label = "natural")
ax0.legend(loc = "lower right")
ax0.set_ylabel("uV")

# Difference
ax1.axvline(x = 0, linestyle = "--", color = "black")
ax1.plot(times_graph, np.mean(np.mean(epochs['manmade'].get_data(picks = electrodes_graph), axis = 0), axis = 0) - np.mean(np.mean(epochs['natural'].get_data(picks = electrodes_graph), axis = 0), axis = 0))
ax1.axhline(y = 0, linestyle = "--", color = "black")
ax1.set_ylabel("Difference")

# T-values
ax2.axvline(x = 0, linestyle = "--", color = "black")
h = None
for i, c in enumerate(clusters):
    c = c[0]
    if p_vals[i] <= 0.05:
        h = ax2.axvspan(times_graph[c.start],
                        times_graph[c.stop - 1],
                        color = 'red',
                        alpha = 0.5)
    else:
        ax2.axvspan(times_graph[c.start],
                    times_graph[c.stop - 1],
                    color = (0.3, 0.3, 0.3),
                    alpha = 0.3)
hf = ax2.plot(times_graph, t_vals, 'g')
if h is not None:
    plt.legend((h, ), ('cluster p-value < 0.05', ))
plt.xlabel("time (ms)")
## Text(0.5, 0, 'time (ms)')
plt.ylabel("t-values")
## Text(0, 0.5, 't-values')
# plt.savefig("figures/fig2.png")
# plt.clf()






















