import sys
import mne
import pandas as pd
import scipy.io
import os
import numpy as np
from scipy.io import loadmat  # this is the SciPy module that loads mat-files
import matplotlib.pyplot as plt
from datetime import datetime, date, time
from os.path import join as opj
from glob import glob
from numpy.random import randn 
from mne.time_frequency import tfr_morlet, write_tfrs
from mne.epochs import equalize_epoch_counts
from scipy.stats import spearmanr, ttest_ind, describe, normaltest, pearsonr
from mne.stats import permutation_cluster_1samp_test, permutation_cluster_test
import time
from mne.viz import plot_tfr_topomap

def ensure_dir(ed):
    import os
    try:
        os.makedirs(ed)
    except OSError:
        if not os.path.isdir(ed):
            raise

# load epoched and autorejected data

# directory with eeg_BIDS data received from the EEG_manypipelines team
path_to_eeg_BIDS = sys.argv[1] 
# directory where the output of the previous step is saved
path_to_TFR_step1_output = sys.argv[2]
# directory where the output of this script is going to be saved
path_to_TFR_step2_output = sys.argv[3]
# directory where the output of this script is going to be saved
path_to_TFR_RQ2_output = sys.argv[4]

subject = 'sub-001'
epochs_old = mne.read_epochs(glob(opj(path_to_TFR_step1_output, 
									  subject, 
									  subject + '*old*epo.fif'))[0], 
							 preload = True, 
							 verbose = 'error')
decim = 1 # specify decimation factor - decimation occors after TFR estimation
times = epochs_old.crop(0, 0.5).decimate(decim).times
epochs_old.pick_types(eeg = True)
info = epochs_old.info
logged_freqs = np.logspace(np.log10(4), np.log10(40), 18)

power_all_subj_old = np.load(opj(path_to_TFR_step2_output, 'power_all_subj_old.npy'))
power_all_subj_new = np.load(opj(path_to_TFR_step2_output, 'power_all_subj_new.npy'))

power_all_old = mne.time_frequency.EpochsTFR(info, power_all_subj_old, times, logged_freqs)
power_all_new = mne.time_frequency.EpochsTFR(info, power_all_subj_new, times, logged_freqs)

# topo-plot for the theta range 4-8Hz
stat_old_vs_new, pval_old_vs_new = ttest_ind(power_all_subj_old.data,
											 power_all_subj_new.data, 
											 axis = 0, 
											 equal_var = False, 
											 nan_policy = 'propagate')


OldVsNew = mne.time_frequency.AverageTFR(power_all_old.info, 
										 stat_old_vs_new[:,0:6,:], 
										 power_all_old.times, 
										 power_all_old.freqs[0:6], 
										 nave = power_all_subj_old.data.shape[0]) # take only the freqs from 4-8HZ

plot_tfr_topomap(OldVsNew, 
				 colorbar = False, 
				 size = 10, 
				 tmin = times[38], 
				 tmax = times[-1], 
				 show_names = False, 
				 unit = None,  
				 cbar_fmt = '%1.2f') # take 0.3s to 0.5s after stim onset

# topo-plot for the alpha range 8-14Hz
stat_old_vs_new, pval_old_vs_new = ttest_ind(power_all_subj_old.data,
											 power_all_subj_new.data, 
											 axis = 0, 
											 equal_var = False, 
											 nan_policy = 'propagate')

OldVsNew = mne.time_frequency.AverageTFR(power_all_old.info, 
										 stat_old_vs_new[:,5:10,:], 
										 power_all_old.times, 
										 power_all_old.freqs[5:10], 
										 nave = power_all_subj_old.data.shape[0]) # take only the freqs from 4-8HZ

plot_tfr_topomap(OldVsNew, 
				 colorbar = False, 
				 size = 10, 
				 tmin = times[38], 
				 tmax = times[-1], 
				 show_names = False, 
				 unit = None, 
				 cbar_fmt = '%1.2f') # take 0.3s to 0.5s after stim onset

# Cluster-Based Permutation test over all channels and freqs - testes both RQ2b and RQ2c simultaneously
start_time = time.time()
# downsampling in case it's needed
power_all_old_down = mne.filter.resample(power_all_old, down = 1)
power_all_new_down = mne.filter.resample(power_all_new, down = 1)

opj(path_to_eeg_BIDS, 'TFR_RQ2')
ensure_dir(opj(path_to_TFR_RQ2_output, 'cache'))
mne.set_cache_dir(opj(path_to_TFR_RQ2_output, 'cache'))

threshold = None
threshold_tfce = dict(start = 0, step = 0.2)
T_obs, clusters, cluster_p_values, H0 = \
    permutation_cluster_test([power_all_old_down[:,:,:,:], power_all_new_down[:,:,:,:]], 
    						 n_jobs = 1,
                             n_permutations = 1000, 
                             threshold = threshold_tfce, 
                             tail = 0, 
                             buffer_size = 100, 
                             verbose = 'error', 
                             seed = 888)

print("--- %s seconds ---" % (time.time() - start_time))
print(cluster_p_values[cluster_p_values < 0.05])

# Cluster-Based Permutation test over 3 midfrontal channels and theta range - RQ2b
channels = ['FC1', 'FCz', 'FC2']
spec_channel_list = []

for i,channel in enumerate(channels):
    factor = 8
    spec_channel_list.append(power_all_old[0].ch_names.index(channel))
spec_channel_list

start_time = time.time()
# downsampling in case it's needed
power_all_old_down=mne.filter.resample(power_all_old, down=1)
power_all_new_down=mne.filter.resample(power_all_new, down=1)

opj(path_to_eeg_BIDS, 'TFR_RQ2')
ensure_dir(opj(path_to_TFR_RQ2_output, 'cache'))
mne.set_cache_dir(opj(path_to_TFR_RQ2_output, 'cache'))

threshold = None
threshold_tfce = dict(start = 0, step = 0.2)
T_obs, clusters, cluster_p_values, H0 = \
    permutation_cluster_test([power_all_old_down[:, spec_channel_list, 0:6,:], power_all_new_down[:, spec_channel_list, 0:6,:]], 
    						 n_jobs = 1,
                             n_permutations = 1000, 
                             threshold = threshold_tfce, 
                             tail = 0, 
                             buffer_size = 100, 
                             verbose = 'error', 
                             seed = 888)

print("--- %s seconds ---" % (time.time() - start_time))
print(cluster_p_values[cluster_p_values < 0.05])

# Cluster-Based Permutation test over posterior channels in alpha range - RQ2c
channels = ['P7', 'P5', 'P3', 'P1', 'P2', 'P4', 'P6']
spec_channel_list = []

for i,channel in enumerate(channels):
    factor = 8
    spec_channel_list.append(power_all_old[0].ch_names.index(channel))
spec_channel_list

start_time = time.time()
# downsampling in case it's needed
power_all_old_down = mne.filter.resample(power_all_old, down = 1)
power_all_new_down = mne.filter.resample(power_all_new, down = 1)

opj(path_to_eeg_BIDS, 'TFR_RQ2')
ensure_dir(opj(path_to_TFR_RQ2_output, 'cache'))
mne.set_cache_dir(opj(path_to_TFR_RQ2_output, 'cache'))

threshold = None
threshold_tfce = dict(start = 0, step = 0.2)
T_obs, clusters, cluster_p_values, H0 = \
    permutation_cluster_test([power_all_old_down[:,spec_channel_list,5:10,:], power_all_new_down[:,spec_channel_list,5:10 ,:]], 
    						 n_jobs = 1,
                             n_permutations = 1000, 
                             threshold = threshold_tfce, 
                             tail = 0, 
                             buffer_size = 100, 
                             verbose = 'error',
                             seed = 888)

print("--- %s seconds ---" % (time.time() - start_time))
print(cluster_p_values[cluster_p_values < 0.05])
