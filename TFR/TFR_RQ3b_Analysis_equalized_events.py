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


'''
loading subs after fitting
'''

bids_root = '../eeg_BIDS/'
prepro_root = '../Preprocessed/'
decim = 1 



subject = 'sub-001'
epochs_old_hit = mne.read_epochs(glob(opj(prepro_root,subject,subject+'*old_hit*epo.fif'))[0],
                                 preload=True,
                                 verbose='error')


times = epochs_old_hit.crop(0,0.5).decimate(decim).times
epochs_old_hit.pick_types(eeg = True)
info = epochs_old_hit.info
logged_freqs = np.logspace(np.log10(4),np.log10(40),18)



out_dir=opj(bids_root,'TFR_RQ3')

power_all_subj_old_hit = np.load(opj(out_dir,'power_all_subj_old_hit.npy'))
power_all_subj_old_miss = np.load(opj(out_dir,'power_all_subj_old_miss.npy'))


power_all_subj_old_hit = mne.time_frequency.EpochsTFR(info, power_all_subj_old_hit, times,logged_freqs)
power_all_subj_old_miss = mne.time_frequency.EpochsTFR(info, power_all_subj_old_miss, times,logged_freqs)


'''
topo-plot
'''
stat_old_hit_vs_miss, pval_old_hit_vs_miss = ttest_ind(power_all_subj_old_hit.data,power_all_subj_old_miss.data, axis=0, equal_var=False, nan_policy='propagate')


OldHitVsOldMiss = mne.time_frequency.AverageTFR(power_all_subj_old_hit.info, stat_old_hit_vs_miss[:,:,:], power_all_subj_old_hit.times, power_all_subj_old_hit.freqs, nave=power_all_subj_old_hit.data.shape[0]) # take only the freqs from 4-8HZ

plot_tfr_topomap(OldHitVsOldMiss, colorbar=False, size=10, show_names=False, unit=None,  cbar_fmt='%1.2f') # take 0.3s to 0.5s after stim onset


#plt.savefig('/data/sebastian/EEG/neural_analysis/Plots&Graphs/topomap_Stroop_logscaled_final32')



'''
Cluster-Based Permutation test over all channels and freqs
'''




start_time = time.time()



# downsampling in case it's needed
power_all_subj_old_hit_down=mne.filter.resample(power_all_subj_old_hit, down=1)
power_all_subj_old_miss_down=mne.filter.resample(power_all_subj_old_miss, down=1)


opj(bids_root,'TFR_RQ3')
ensure_dir(opj(out_dir,'cache'))
mne.set_cache_dir(opj(out_dir,'cache'))


threshold = None
threshold_tfce = dict(start=0, step=0.2)
T_obs, clusters, cluster_p_values, H0 = \
    permutation_cluster_test([power_all_subj_old_hit_down[:,:,:,:],
                              power_all_subj_old_miss_down[:,:,:,:]],
                             n_jobs = 1,
                             n_permutations = 1000,
                             threshold = threshold_tfce,
                             tail = 0,
                             buffer_size = 100,
                             verbose = 'error',
                             seed = 888)


print("--- %s seconds ---" % (time.time() - start_time))
print(cluster_p_values[cluster_p_values<0.05])