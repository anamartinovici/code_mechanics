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

def ensure_dir(ed):
    import os
    try:
        os.makedirs(ed)
    except OSError:
        if not os.path.isdir(ed):
            raise

'''
load epoched and autorejected data
'''

# starting from a relative path /eeg_BIDS which you should also have
bids_root = '../eeg_BIDS/'
prepro_root = '../Preprocessed/'

subs = [ name for name in os.listdir(bids_root) if name.startswith('sub') ]

#=========================================================================
# === just for initiating some params, I need to read one epoch to fill them out
logged_freqs=np.logspace(np.log10(4),np.log10(40),18)

n_cycles = logged_freqs / 2.

decim = 1 # specify decimation factor - decimation occors after TFR estimation

njobs = 10
n_subj = len(subs)
n_freqs      = len(logged_freqs)
power_all    = dict();itc_all     = dict()#[subj * chan * freqs * time]
power_avgAll = dict(); itc_avgAll = dict()#[chan * freqs * time]

subject=subs[0]
epochs_RQ2 = mne.read_epochs(glob(opj(prepro_root,subject,subject+'*old*epo.fif'))[0], preload=True, verbose='error')
epochs_RQ2.decimate(decim)


# preallocate matrices
n_epochs, n_chan, n_times = epochs_RQ2.pick_types(eeg=True).crop(0, 0.5).get_data().shape
power_all_subj_new = randn(n_subj, n_chan, n_freqs, n_times) * 0

n_epochs, n_chan, n_times = epochs_RQ2.pick_types(eeg=True).crop(0, 0.5).get_data().shape
power_all_subj_old = randn(n_subj, n_chan, n_freqs, n_times) * 0


"""
==============================================================================
    Read all subject
    Apply tfr_morlet
==============================================================================
"""
subj_num_id=0

# loop over subjects to transform to the time-frequency domain

for subject in subs:
    print(subject)
    '''
    new
    '''
    #picks = mne.pick_channels(raw.info["ch_names"], ["C3", "Cz", "C4"]) # In case specific channels are to be picked - also need to add the picks parameter to the next function
    epochs_old = mne.read_epochs(glob(opj(prepro_root,subject,subject+'*old*epo.fif'))[0], preload=True, verbose='error')
    epochs_new = mne.read_epochs(glob(opj(prepro_root,subject,subject+'*new*epo.fif'))[0], preload=True, verbose='error')

    equalize_epoch_counts([epochs_old, epochs_new])  
    
    # Run TF decomposition overall epochs
    tfr_pwr_new = tfr_morlet(epochs_new, freqs=logged_freqs, n_cycles=n_cycles,return_itc=False, n_jobs=njobs, average=True, decim=decim)
    
    # Baseline power
    tfr_pwr_new.apply_baseline(mode='logratio', baseline=(-0.3, 0))
    tfr_pwr_new.crop(0, 0.5)
    power_all_subj_new[subj_num_id,:,:,:] = tfr_pwr_new.data

    info  = tfr_pwr_new.info
    times = tfr_pwr_new.times
    
    # plot all channels averaged
    tfr_pwr_new.plot_joint(title='All Channels New')

    
    '''
    old
    '''
    # Run TF decomposition overall epochs
    tfr_pwr_old = tfr_morlet(epochs_old, freqs=logged_freqs, n_cycles=n_cycles,return_itc=False, n_jobs=njobs, average=True, decim=decim)
    
    # Baseline power
    tfr_pwr_old.apply_baseline(mode='logratio', baseline=(-0.3, 0))
    tfr_pwr_old.crop(0, 0.5)
    power_all_subj_old[subj_num_id,:,:,:] = tfr_pwr_old.data

    # plot all channels averaged
    tfr_pwr_old.plot_joint(title='All Channels Old')
    
    
    subj_num_id+=1

    
# put data across subs in containers
power_all_new = mne.time_frequency.EpochsTFR(info, power_all_subj_new, times,logged_freqs)

# safe TFR data for all subs as numpy array
ensure_dir(opj(bids_root,'TFR_RQ2'))

np.save(opj(bids_root,'TFR_RQ2','power_all_subj_new'),power_all_subj_new)
np.save(opj(bids_root,'TFR_RQ2','power_all_subj_old'),power_all_subj_old)


write_tfrs(opj(bids_root,'TFR_RQ2','pwr_new-tfr.h5'),power_all_new, overwrite=True )

power_all_old = mne.time_frequency.EpochsTFR(info, power_all_subj_old, times,logged_freqs)

write_tfrs(opj(bids_root,'TFR_RQ2','pwr_old-tfr.h5'),power_all_old, overwrite=True)



# loading subs after fitting
bids_root = '../eeg_BIDS/'
prepro_root = '../Preprocessed/'
decim = 1 



subject='sub-001'
epochs_old = mne.read_epochs(glob(opj(prepro_root,subject,subject+'*old*epo.fif'))[0], preload=True, verbose='error')


times=epochs_old.crop(0,0.5).decimate(decim).times
epochs_old.pick_types(eeg=True)
info=epochs_old.info
logged_freqs=np.logspace(np.log10(4),np.log10(40),18)



out_dir=opj(bids_root,'TFR_RQ2')

power_all_subj_old=np.load(opj(out_dir,'power_all_subj_old.npy'))
power_all_subj_new=np.load(opj(out_dir,'power_all_subj_new.npy'))


power_all_old = mne.time_frequency.EpochsTFR(info, power_all_subj_old, times,logged_freqs)
power_all_new = mne.time_frequency.EpochsTFR(info, power_all_subj_new, times,logged_freqs)


'''
topo-plot for the theta range 4-8Hz
'''
stat_old_vs_new, pval_old_vs_new = ttest_ind(power_all_subj_old.data,power_all_subj_new.data, axis=0, equal_var=False, nan_policy='propagate')


OldVsNew = mne.time_frequency.AverageTFR(power_all_old.info, stat_old_vs_new[:,0:6,:], power_all_old.times, power_all_old.freqs[0:6], nave=power_all_subj_old.data.shape[0]) # take only the freqs from 4-8HZ
from mne.viz import plot_tfr_topomap
plot_tfr_topomap(OldVsNew, colorbar=False, size=10, tmin=times[38], tmax=times[-1], show_names=False, unit=None,  cbar_fmt='%1.2f') # take 0.3s to 0.5s after stim onset


'''
topo-plot for the alpha range 8-14Hz
'''
stat_old_vs_new, pval_old_vs_new = ttest_ind(power_all_subj_old.data,power_all_subj_new.data, axis=0, equal_var=False, nan_policy='propagate')


OldVsNew = mne.time_frequency.AverageTFR(power_all_old.info, stat_old_vs_new[:,5:10,:], power_all_old.times, power_all_old.freqs[5:10], nave=power_all_subj_old.data.shape[0]) # take only the freqs from 4-8HZ
from mne.viz import plot_tfr_topomap
plot_tfr_topomap(OldVsNew, colorbar=False, size=10, tmin=times[38], tmax=times[-1], show_names=False, unit=None,  cbar_fmt='%1.2f') # take 0.3s to 0.5s after stim onset



'''
Cluster-Based Permutation test over all channels and freqs - testes both RQ2b and RQ2c simultaneously
'''




start_time = time.time()



# downsampling in case it's needed
power_all_old_down=mne.filter.resample(power_all_old, down=1)
power_all_new_down=mne.filter.resample(power_all_new, down=1)


opj(bids_root,'TFR_RQ2')
ensure_dir(opj(out_dir,'cache'))
mne.set_cache_dir(opj(out_dir,'cache'))


threshold = None
threshold_tfce = dict(start=0, step=0.2)
T_obs, clusters, cluster_p_values, H0 = \
    permutation_cluster_test([power_all_old_down[:,:,:,:], power_all_new_down[:,:,:,:]], n_jobs=1,
                             n_permutations=1000, threshold=threshold_tfce, tail=0, buffer_size=100, verbose='error', seed=888)


print("--- %s seconds ---" % (time.time() - start_time))
print(cluster_p_values[cluster_p_values<0.05])



'''
Cluster-Based Permutation test over 3 midfrontal channels and theta range - RQ2b
'''

channels=['FC1','FCz','FC2']
spec_channel_list=[]

for i,channel in enumerate(channels):
    factor=8
    spec_channel_list.append(power_all_old[0].ch_names.index(channel))
spec_channel_list



start_time = time.time()



# downsampling in case it's needed
power_all_old_down=mne.filter.resample(power_all_old, down=1)
power_all_new_down=mne.filter.resample(power_all_new, down=1)


opj(bids_root,'TFR_RQ2')
ensure_dir(opj(out_dir,'cache'))
mne.set_cache_dir(opj(out_dir,'cache'))


threshold = None
threshold_tfce = dict(start=0, step=0.2)
T_obs, clusters, cluster_p_values, H0 = \
    permutation_cluster_test([power_all_old_down[:,spec_channel_list,0:6,:], power_all_new_down[:,spec_channel_list,0:6,:]], n_jobs=1,
                             n_permutations=1000, threshold=threshold_tfce, tail=0, buffer_size=100, verbose='error', seed=888)


print("--- %s seconds ---" % (time.time() - start_time))
print(cluster_p_values[cluster_p_values<0.05])



'''
Cluster-Based Permutation test over posterior channels in alpha range - RQ2c
'''

channels=['P7','P5','P3','P1','P2','P4','P6']
spec_channel_list=[]

for i,channel in enumerate(channels):
    factor=8
    spec_channel_list.append(power_all_old[0].ch_names.index(channel))
spec_channel_list



start_time = time.time()



# downsampling in case it's needed
power_all_old_down=mne.filter.resample(power_all_old, down=1)
power_all_new_down=mne.filter.resample(power_all_new, down=1)


opj(bids_root,'TFR_RQ2')
ensure_dir(opj(out_dir,'cache'))
mne.set_cache_dir(opj(out_dir,'cache'))


threshold = None
threshold_tfce = dict(start=0, step=0.2)
T_obs, clusters, cluster_p_values, H0 = \
    permutation_cluster_test([power_all_old_down[:,spec_channel_list,5:10,:], power_all_new_down[:,spec_channel_list,5:10 ,:]], n_jobs=1,
                             n_permutations=1000, threshold=threshold_tfce, tail=0, buffer_size=100, verbose='error', seed=888)


print("--- %s seconds ---" % (time.time() - start_time))
print(cluster_p_values[cluster_p_values<0.05])