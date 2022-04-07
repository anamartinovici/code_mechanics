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
epochs_RQ4 = mne.read_epochs(glob(opj(prepro_root,subject,subject+'*remembered*epo.fif'))[0],
                             preload=True,
                             verbose='error')
epochs_RQ4.decimate(decim)


# preallocate matrices
n_epochs, n_chan, n_times = epochs_RQ4.pick_types(eeg=True).crop(0, 0.5).get_data().shape
power_all_subj_rem = randn(n_subj, n_chan, n_freqs, n_times) * 0

n_epochs, n_chan, n_times = epochs_RQ4.pick_types(eeg=True).crop(0, 0.5).get_data().shape
power_all_subj_forg = randn(n_subj, n_chan, n_freqs, n_times) * 0


"""
==============================================================================
    Read all subject
    Apply tfr_morlet
==============================================================================
"""
subj_num_id=0

# loop over subjects to transform to the time-frequency domain

for subject in subs[:12]:
    print(subject)
    '''
    epochs_old_hit
    '''
    #picks = mne.pick_channels(raw.info["ch_names"], ["C3", "Cz", "C4"]) # In case specific channels are to be picked - also need to add the picks parameter to the next function
    epochs_rem = mne.read_epochs(glob(opj(prepro_root,subject,subject+'*remembered*epo.fif'))[0],
                                     preload=True,
                                     verbose='error')
    
    epochs_forg = mne.read_epochs(glob(opj(prepro_root,subject,subject+'*forgotten*epo.fif'))[0],
                                      preload=True,
                                      verbose='error')

    #print(epochs_rem.get_data().shape[0])
    #print(epochs_forg.get_data().shape[0])
    
    equalize_epoch_counts([epochs_rem, epochs_forg])  
    
    #print(epochs_rem.get_data().shape[0])
    #print(epochs_forg.get_data().shape[0])
    
    # Run TF decomposition overall epochs
    tfr_pwr_rem = tfr_morlet(epochs_rem,
                                 freqs=logged_freqs,
                                 n_cycles=n_cycles,
                                 return_itc=False,
                                 n_jobs=njobs,
                                 average=True,
                                 decim=decim)
    
    # Baseline power
    tfr_pwr_rem.apply_baseline(mode='logratio', baseline=(-0.3, 0))
    tfr_pwr_rem.crop(0, 0.5)
    power_all_subj_rem[subj_num_id,:,:,:] = tfr_pwr_rem.data

    info  = tfr_pwr_rem.info
    times = tfr_pwr_rem.times
    
    # plot all channels averaged
    tfr_pwr_rem.plot_joint(title='All Channels New')

    
    '''
    old_miss
    '''
    # Run TF decomposition overall epochs
    tfr_pwr_forg = tfr_morlet(epochs_forg,
                                  freqs=logged_freqs,
                                  n_cycles=n_cycles,
                                  return_itc=False,
                                  n_jobs=njobs,
                                  average=True,
                                  decim=decim)
    
    # Baseline power
    tfr_pwr_forg.apply_baseline(mode='logratio', baseline=(-0.3, 0))
    tfr_pwr_forg.crop(0, 0.5)
    power_all_subj_forg[subj_num_id,:,:,:] = tfr_pwr_forg.data

    # plot all channels averaged
    tfr_pwr_forg.plot_joint(title='All Channels Old')
    
    
    subj_num_id+=1


# safe TFR data for all subs as numpy array
ensure_dir(opj(bids_root,'TFR_RQ4'))
    
# put data across subs in containers
power_all_rem = mne.time_frequency.EpochsTFR(info, power_all_subj_rem, times,logged_freqs)

np.save(opj(bids_root,'TFR_RQ4','power_all_subj_rem'),power_all_rem)
np.save(opj(bids_root,'TFR_RQ4','power_all_subj_forg'),power_all_subj_forg)


write_tfrs(opj(bids_root,'TFR_RQ4','pwr_rem-tfr.h5'),power_all_rem, overwrite=True )

power_all_forg = mne.time_frequency.EpochsTFR(info, power_all_subj_forg, times,logged_freqs)

write_tfrs(opj(bids_root,'TFR_RQ4','pwr_forg-tfr.h5'),power_all_forg, overwrite=True)

