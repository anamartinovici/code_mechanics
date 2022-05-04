def f_TFR_RQ4b_decomp_NOTeq(project_seed, path_to_eeg_BIDS, path_to_TFR_step1_output, path_to_TFR_RQ4_output):
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
    epochs_RQ4 = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*remembered*epo.fif"))[0],
                                 preload = True,
                                 verbose = "error")
    epochs_RQ4.decimate(decim)
    
    # preallocate matrices
    n_epochs, n_chan, n_times = epochs_RQ4.pick_types(eeg = True).crop(0, 0.5).get_data().shape
    power_all_subj_rem = randn(n_subj, n_chan, n_freqs, n_times) * 0
    power_all_subj_forg = randn(n_subj, n_chan, n_freqs, n_times) * 0
    
    
    # Read all subjects
    # loop over subjects to transform to the time-frequency domain
    # Apply tfr_morlet
    
    subj_num_id = 0
    for subject in subs:
        print(subject)
        # In case specific channels are to be picked - also need to add the picks parameter to the next function
        # picks = mne.pick_channels(raw.info["ch_names"], ["C3", "Cz", "C4"]) 
        epochs_rem = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*remembered*epo.fif"))[0],
                                         preload = True,
                                         verbose = "error")
        
        epochs_forg = mne.read_epochs(glob(opj(path_to_TFR_step1_output,subject,subject + "*forgotten*epo.fif"))[0],
                                          preload = True,
                                          verbose = "error")
    
        print(epochs_rem.get_data().shape[0])
        print(epochs_forg.get_data().shape[0])
        
        # Run TF decomposition overall epochs
        tfr_pwr_rem = mne.time_frequency.tfr_morlet(epochs_rem,
                                                    freqs = logged_freqs,
                                                    n_cycles = n_cycles,
                                                    return_itc = False,
                                                    n_jobs = njobs,
                                                    average = True,
                                                    decim = decim)
        
        # Baseline power
        tfr_pwr_rem.apply_baseline(mode = "logratio", baseline = (-0.3, 0))
        tfr_pwr_rem.crop(0, 0.5)
        power_all_subj_rem[subj_num_id,:,:,:] = tfr_pwr_rem.data
    
        info  = tfr_pwr_rem.info
        times = tfr_pwr_rem.times
        
        # plot all channels averaged
        tfr_pwr_rem.plot_joint(title = "All Channels Remembered")
        
        # Run TF decomposition overall epochs
        tfr_pwr_forg = mne.time_frequency.tfr_morlet(epochs_forg,
                                                     freqs = logged_freqs,
                                                     n_cycles = n_cycles,
                                                     return_itc = False,
                                                     n_jobs = njobs,
                                                     average = True,
                                                     decim = decim)
        
        # Baseline power
        tfr_pwr_forg.apply_baseline(mode = "logratio", baseline = (-0.3, 0))
        tfr_pwr_forg.crop(0, 0.5)
        power_all_subj_forg[subj_num_id,:,:,:] = tfr_pwr_forg.data
    
        # plot all channels averaged
        tfr_pwr_forg.plot_joint(title = "All Channels Forgotten")
        
        subj_num_id+=1
    
    
    np.save(opj(path_to_TFR_RQ4_output, "not_equalized", "power_all_subj_rem"), power_all_subj_rem)
    np.save(opj(path_to_TFR_RQ4_output, "not_equalized", "power_all_subj_forg"), power_all_subj_forg)
    
