def f_TFR_RQ3b_decomp_eq(project_seed, path_to_eeg_BIDS, path_to_TFR_step1_output, path_to_TFR_RQ3_output):
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
    epochs_RQ3 = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*old_hit*epo.fif"))[0],
                                 preload = True,
                                 verbose = "error")
    epochs_RQ3.decimate(decim)
    
    # preallocate matrices
    n_epochs, n_chan, n_times = epochs_RQ3.pick_types(eeg = True).crop(0, 0.5).get_data().shape
    power_all_subj_old_hit = randn(n_subj, n_chan, n_freqs, n_times) * 0
    power_all_subj_old_miss = randn(n_subj, n_chan, n_freqs, n_times) * 0
    
    # Read all subjects
    # loop over subjects to transform to the time-frequency domain
    # Apply tfr_morlet
    
    subj_num_id = 0
    for subject in subs:
        print(subject)
        
        # epochs_old_hit
        
        # In case specific channels are to be picked - also need to add the picks parameter to the next function
        # picks = mne.pick_channels(raw.info["ch_names"], ["C3", "Cz", "C4"]) 
        epochs_old_hit = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*old_hit*epo.fif"))[0],
                                         preload = True,
                                         verbose = "error")
        
        epochs_old_miss = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*old_miss*epo.fif"))[0],
                                          preload = True,
                                          verbose = "error")
    
        print(epochs_old_hit.get_data().shape[0])
        print(epochs_old_miss.get_data().shape[0])
        
        mne.epochs.equalize_epoch_counts([epochs_old_hit, epochs_old_miss])  
        
        print(epochs_old_hit.get_data().shape[0])
        print(epochs_old_miss.get_data().shape[0])
        
        # Run TF decomposition overall epochs
        tfr_pwr_old_hit = mne.time_frequency.tfr_morlet(epochs_old_hit,
                                                        freqs = logged_freqs,
                                                        n_cycles = n_cycles,
                                                        return_itc = False,
                                                        n_jobs = njobs,
                                                        average = True,
                                                        decim = decim)
        
        # Baseline power
        tfr_pwr_old_hit.apply_baseline(mode = "logratio", baseline = (-0.3, 0))
        tfr_pwr_old_hit.crop(0, 0.5)
        power_all_subj_old_hit[subj_num_id,:,:,:] = tfr_pwr_old_hit.data
    
        info  = tfr_pwr_old_hit.info
        times = tfr_pwr_old_hit.times
        
        # plot all channels averaged
        tfr_pwr_old_hit.plot_joint(title = "All Channels Old Hit")
    
        # old_miss
        # Run TF decomposition overall epochs
        tfr_pwr_old_miss = mne.time_frequency.tfr_morlet(epochs_old_miss,
                                                         freqs = logged_freqs,
                                                         n_cycles = n_cycles,
                                                         return_itc = False,
                                                         n_jobs = njobs,
                                                         average = True,
                                                         decim = decim)
        
        # Baseline power
        tfr_pwr_old_miss.apply_baseline(mode = "logratio", baseline = (-0.3, 0))
        tfr_pwr_old_miss.crop(0, 0.5)
        power_all_subj_old_miss[subj_num_id,:,:,:] = tfr_pwr_old_miss.data
    
        # plot all channels averaged
        tfr_pwr_old_miss.plot_joint(title = "All Channels Old Miss")
        
        
        subj_num_id+=1
    
    np.save(opj(path_to_TFR_RQ3_output, "equalized", "power_all_subj_old_hit"), power_all_subj_old_hit)
    np.save(opj(path_to_TFR_RQ3_output, "equalized", "power_all_subj_old_miss"), power_all_subj_old_miss)
    
    
