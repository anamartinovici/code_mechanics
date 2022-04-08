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

# directory with eeg_BIDS data received from the EEG_manypipelines team
path_to_eeg_BIDS = sys.argv[1] 
# directory where the output of the previous step is saved
path_to_TFR_step1_output = sys.argv[2]
path_to_TFR_RQ4_output   = sys.argv[3]
path_to_cache_dir = sys.argv[4]

decim = 1 

subject = 'sub-001'
epochs_old_hit = mne.read_epochs(glob(opj(path_to_TFR_step1_output,subject,subject+'*remembered*epo.fif'))[0],
                                 preload=True,
                                 verbose='error')

times = epochs_old_hit.crop(0,0.5).decimate(decim).times
epochs_old_hit.pick_types(eeg = True)
info = epochs_old_hit.info
logged_freqs = np.logspace(np.log10(4),np.log10(40),18)

power_all_subj_rem = np.load(opj(path_to_TFR_RQ4_output, 'not_equalized', 'power_all_subj_rem.npy'))
power_all_subj_forg = np.load(opj(path_to_TFR_RQ4_output, 'not_equalized', 'power_all_subj_forg.npy'))

power_all_subj_rem = mne.time_frequency.EpochsTFR(info, power_all_subj_rem, times,logged_freqs)
power_all_subj_forg = mne.time_frequency.EpochsTFR(info, power_all_subj_forg, times,logged_freqs)


'''
topo-plot 
'''
stat_old_hit_vs_miss, pval_old_hit_vs_miss = ttest_ind(power_all_subj_rem.data,power_all_subj_forg.data, axis=0, equal_var=False, nan_policy='propagate')

OldHitVsOldMiss = mne.time_frequency.AverageTFR(power_all_subj_rem.info, stat_old_hit_vs_miss[:,:,:], power_all_subj_rem.times, power_all_subj_rem.freqs, nave=power_all_subj_rem.data.shape[0]) # take only the freqs from 4-8HZ

# plot_tfr_topomap(OldHitVsOldMiss, colorbar=False, size=10, show_names=False, unit=None,  cbar_fmt='%1.2f') # take 0.3s to 0.5s after stim onset
# plt.savefig('/data/sebastian/EEG/neural_analysis/Plots&Graphs/topomap_Stroop_logscaled_final32')


################
#
# Cluster-Based Permutation tests

mne.set_cache_dir(path_to_cache_dir)

# all cluster-based permutations tests use the same threshhold
threshold_tfce = dict(start = 0, step = 0.2)
# all cluster-based permutations tests use the same number of jobs (cores)
n_cores = 1
# all cluster-based permutations tests use the same number of permutations (1000)
n_perm = 10


'''
Cluster-Based Permutation test over all channels and freqs
'''
start_time = time.time()
T_obs, clusters, cluster_p_values, H0 = \
    permutation_cluster_test([power_all_subj_rem.data[:,:,:,:],
                              power_all_subj_forg.data[:,:,:,:]],
                             n_jobs = n_cores,
                             n_permutations = n_perm,
                             threshold = threshold_tfce,
                             tail = 0, 
                             buffer_size = 100,
                             verbose = 'error', 
                             seed = 888)
print("--- %s seconds ---" % (time.time() - start_time))
print(cluster_p_values[cluster_p_values<0.05])
