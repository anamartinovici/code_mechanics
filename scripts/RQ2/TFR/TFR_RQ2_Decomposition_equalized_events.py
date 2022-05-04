def f_TFR_RQ2_decomp_eq(project_seed, path_to_eeg_BIDS, path_to_TFR_step1_output, path_to_TFR_RQ2_output):
    import mne
    import random
    
    import numpy as np
    
    from os.path import join as opj
    from glob import glob
    from numpy.random import randn 
    
    # set seed to ensure computational reproducibility
    random.seed(project_seed) 
    
    subs = [ name for name in os.listdir(path_to_eeg_BIDS) if name.startswith("sub") ]
    
    # just for initiating some params, I need to read one epoch to fill them out
    logged_freqs = np.logspace(np.log10(4), np.log10(40), 18)
    n_cycles = logged_freqs / 2.
    # specify decimation factor - decimation occurs after TFR estimation
    decim = 1 
    njobs = 4
    n_subj = len(subs)
    n_freqs = len(logged_freqs)
    
    subject = subs[0]
    epochs_RQ2 = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*old*epo.fif"))[0], 
                                 preload = True, 
                                 verbose = "error")
    epochs_RQ2.decimate(decim)
    
    # preallocate matrices
    n_epochs, n_chan, n_times = epochs_RQ2.pick_types(eeg = True).crop(0, 0.5).get_data().shape
    power_all_subj_new = randn(n_subj, n_chan, n_freqs, n_times) * 0
    power_all_subj_old = randn(n_subj, n_chan, n_freqs, n_times) * 0
    
    # loop over subjects to transform to the time-frequency domain
    subj_num_id = 0
    for subject in subs:
        print(subject)
        
        epochs_old = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*old*epo.fif"))[0], 
                                     preload = True, 
                                     verbose = "error")
        epochs_new = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*new*epo.fif"))[0], 
                                     preload = True, 
                                     verbose = "error")
    
        mne.epochs.equalize_epoch_counts([epochs_old, epochs_new])  
        
        # Run TF decomposition overall epochs
        tfr_pwr_new = mne.time_frequency.tfr_morlet(epochs_new, 
        				                            freqs = logged_freqs, 
        						                    n_cycles = n_cycles, 
        						                    return_itc = False, 
        						                    n_jobs = njobs, 
        						                    average = True, 
        						                    decim = decim)
        
        # Baseline power
        tfr_pwr_new.apply_baseline(mode = "logratio", baseline = (-0.3, 0))
        tfr_pwr_new.crop(0, 0.5)
        power_all_subj_new[subj_num_id,:,:,:] = tfr_pwr_new.data
    
        info  = tfr_pwr_new.info
        times = tfr_pwr_new.times
        
        # plot all channels averaged
        tfr_pwr_new.plot_joint(title = "All Channels New")
    
        # Run TF decomposition overall epochs
        tfr_pwr_old = mne.time_frequency.tfr_morlet(epochs_old, 
        						                    freqs = logged_freqs, 
        						                    n_cycles = n_cycles,
        						                    return_itc = False, 
        						                    n_jobs = njobs, 
        						                    average = True, 
        						                    decim = decim)
        
        # Baseline power
        tfr_pwr_old.apply_baseline(mode = "logratio", baseline = (-0.3, 0))
        tfr_pwr_old.crop(0, 0.5)
        power_all_subj_old[subj_num_id,:,:,:] = tfr_pwr_old.data
    
        # plot all channels averaged
        tfr_pwr_old.plot_joint(title = "All Channels Old")
        
        subj_num_id+=1
    
    np.save(opj(path_to_TFR_RQ2_output, "equalized", "power_all_subj_new"), power_all_subj_new)
    np.save(opj(path_to_TFR_RQ2_output, "equalized", "power_all_subj_old"), power_all_subj_old)
    
