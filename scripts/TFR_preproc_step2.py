def f_TFR_preproc_step2(project_seed, path_to_eeg_BIDS, path_to_TFR_step1_output, path_to_TFR_step2_output):
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
    
    def ensure_dir(ed):
        import os
        try:
            os.makedirs(ed)
        except OSError:
            if not os.path.isdir(ed):
                raise
    
    
    # directory with eeg_BIDS data received from the EEG_manypipelines team
    #path_to_eeg_BIDS = sys.argv[1] 
    # directory where the output of the previous step is saved
    #path_to_TFR_step1_output = sys.argv[2]
    # directory where the output of this script is going to be saved
    #path_to_TFR_step2_output = sys.argv[3]
    
    subs = [ name for name in os.listdir(path_to_eeg_BIDS) if name.startswith('sub') ]
    
    #=========================================================================
    # === just for initiating some params, I need to read one epoch to fill them out
    logged_freqs = np.logspace(np.log10(4), np.log10(40), 18)
    
    n_cycles     = logged_freqs / 2.
    decim        = 1 # specify decimation factor - decimation occors after TFR estimation
    njobs        = 1
    n_subj       = len(subs)
    n_freqs      = len(logged_freqs)
    #power_all    = dict();
    #itc_all      = dict()#[subj * chan * freqs * time]
    #power_avgAll = dict(); 
    #itc_avgAll = dict()#[chan * freqs * time]
    
    subject = subs[0]
    epochs_RQ2 = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + '*old*epo.fif'))[0], preload = True, verbose = 'error')
    epochs_RQ2.decimate(decim)
    
    # preallocate matrices
    # Is there no other way of creating an empty array?
    # I find it weird that you need to sample from a standard normal distribution
    n_epochs, n_chan, n_times = epochs_RQ2.pick_types(eeg = True).crop(0, 0.5).get_data().shape
    power_all_subj_new = randn(n_subj, n_chan, n_freqs, n_times) * 0
    
    n_epochs, n_chan, n_times = epochs_RQ2.pick_types(eeg = True).crop(0, 0.5).get_data().shape
    power_all_subj_old = randn(n_subj, n_chan, n_freqs, n_times) * 0
    
    
    """
    ==============================================================================
        Read all subject
        Apply tfr_morlet
    ==============================================================================
    """
    
    # loop over subjects to transform to the time-frequency domain
    subj_num_id=0
    for subject in subs:
        print(subject)
        
        '''
        new
        '''
        epochs_old = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + '*old*epo.fif'))[0], preload = True, verbose = 'error')
        epochs_new = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + '*new*epo.fif'))[0], preload = True, verbose = 'error')
    
        equalize_epoch_counts([epochs_old, epochs_new])  
        
        # Run TF decomposition overall epochs
        tfr_pwr_new = tfr_morlet(epochs_new, 
        						 freqs = logged_freqs, 
        						 n_cycles = n_cycles, 
        						 return_itc = False, 
        						 n_jobs = njobs, 
        						 average = True, 
        						 decim = decim)
        
        # Baseline power
        tfr_pwr_new.apply_baseline(mode = 'logratio', baseline = (-0.3, 0))
        tfr_pwr_new.crop(0, 0.5)
        power_all_subj_new[subj_num_id,:,:,:] = tfr_pwr_new.data
    
        info  = tfr_pwr_new.info
        times = tfr_pwr_new.times
        
        # plot all channels averaged
        # if you need the plots, then you should save them. 
        # Otherwise you have to click to close each plot when executing this script in the terminal
        # tfr_pwr_new.plot_joint(title = 'All Channels New')
    
        
        '''
        old
        '''
        # Run TF decomposition overall epochs
        tfr_pwr_old = tfr_morlet(epochs_old, 
        						 freqs = logged_freqs, 
        						 n_cycles = n_cycles,
        						 return_itc = False, 
        						 n_jobs = njobs, 
        						 average = True, 
        						 decim = decim)
        
        # Baseline power
        tfr_pwr_old.apply_baseline(mode='logratio', baseline=(-0.3, 0))
        tfr_pwr_old.crop(0, 0.5)
        power_all_subj_old[subj_num_id,:,:,:] = tfr_pwr_old.data
    
        # plot all channels averaged
        #tfr_pwr_old.plot_joint(title='All Channels Old')
        
        subj_num_id+=1
    
        
    # put data across subs in containers
    power_all_new = mne.time_frequency.EpochsTFR(info, power_all_subj_new, times,logged_freqs)
    
    # save TFR data for all subs as numpy array
    ensure_dir(opj(path_to_TFR_step2_output))
    
    np.save(opj(path_to_TFR_step2_output,'power_all_subj_new'),power_all_subj_new)
    np.save(opj(path_to_TFR_step2_output, 'power_all_subj_old'),power_all_subj_old)
    write_tfrs(opj(path_to_TFR_step2_output, 'pwr_new-tfr.h5'),power_all_new, overwrite=True )
    
    power_all_old = mne.time_frequency.EpochsTFR(info, power_all_subj_old, times,logged_freqs)
    
    write_tfrs(opj(path_to_TFR_step2_output, 'pwr_old-tfr.h5'),power_all_old, overwrite=True)
    
    
    
