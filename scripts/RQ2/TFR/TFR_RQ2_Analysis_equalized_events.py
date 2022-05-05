def f_TFR_RQ2_analysis_eq(project_seed, path_to_TFR_step1_output, path_to_TFR_RQ2_output, path_to_cache_dir):
    import mne
    import random
    import time
    
    import numpy as np
    
    from os.path import join as opj
    from glob import glob
    from scipy.stats import ttest_ind
    
    # specify decimation factor - decimation occurs after TFR estimation
    decim = 1 
    
    subject = "sub-001"
    epochs_old = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*old*epo.fif"))[0], 
                                 preload = True, 
                                 verbose = "error")
    times = epochs_old.crop(0, 0.5).decimate(decim).times
    epochs_old.pick_types(eeg = True)
    info = epochs_old.info
    logged_freqs = np.logspace(np.log10(4), np.log10(40), 18)
    
    power_all_subj_old = np.load(opj(path_to_TFR_RQ2_output, "equalized", "power_all_subj_old.npy"))
    power_all_subj_new = np.load(opj(path_to_TFR_RQ2_output, "equalized", "power_all_subj_new.npy"))
    
    power_all_old = mne.time_frequency.EpochsTFR(info, power_all_subj_old, times, logged_freqs)
    power_all_new = mne.time_frequency.EpochsTFR(info, power_all_subj_new, times, logged_freqs)
    
    stat_old_vs_new, pval_old_vs_new = ttest_ind(power_all_subj_old.data,
                                                 power_all_subj_new.data, 
                                                 axis = 0, 
                                                 equal_var = False, 
                                                 nan_policy = "propagate")
    
    # topo-plot for the theta range 4-8Hz
    OldVsNew_theta = mne.time_frequency.AverageTFR(power_all_old.info, 
                                                   stat_old_vs_new[:,0:6,:], 
                                                   power_all_old.times, 
                                                   power_all_old.freqs[0:6], 
                                                   nave = power_all_subj_old.data.shape[0])
    
    print("--------------------")
    print("--- Plot OldVsNew_theta ---")
    print("--------------------")
    # take 0.3s to 0.5s after stim onset
    mne.viz.plot_tfr_topomap(OldVsNew_theta, 
                             colorbar = False, 
                             size = 10, 
                             tmin = times[38], 
                             tmax = times[-1], 
                             show_names = False, 
                             unit = None, 
                             cbar_fmt = "%1.2f")
    
    # topo-plot for the alpha range 8-14Hz
    OldVsNew_alpha = mne.time_frequency.AverageTFR(power_all_old.info, 
                                                   stat_old_vs_new[:,5:10,:], 
                                                   power_all_old.times, 
                                                   power_all_old.freqs[5:10], 
                                                   nave = power_all_subj_old.data.shape[0])

    print("--------------------")
    print("--- Plot OldVsNew_alpha ---")
    print("--------------------")
    # take 0.3s to 0.5s after stim onset
    mne.viz.plot_tfr_topomap(OldVsNew_alpha, 
                             colorbar = False, 
                             size = 10,
                             tmin = times[38], 
                             tmax = times[-1], 
                             show_names = False, 
                             unit = None, 
                             cbar_fmt = "%1.2f") 
    
    # Cluster-Based Permutation tests
    mne.set_cache_dir(path_to_cache_dir)
    threshold_tfce = dict(start = 0, step = 0.2)
    n_cores = 4
    n_perm = 1000
    print("--------------------")
    print("%s%s" % ("number of cores: ", n_cores))
    print("%s%s" % ("number of permutations: ", n_perm))
    print("--------------------")

    # Cluster-Based Permutation test over all channels and freqs - tests both RQ2b and RQ2c simultaneously
    start_time = time.time()
    T_obs, clusters, cluster_p_values, H0 = \
        mne.stats.permutation_cluster_test([power_all_old.data[:,:,:,:], 
                                            power_all_new.data[:,:,:,:]], 
                                           n_jobs = n_cores,
                                           n_permutations = n_perm,
                                           threshold = threshold_tfce,
                                           tail = 0, 
                                           buffer_size = 100,
                                           verbose = "error", 
                                           seed = 888)
    print("--------------------")
    print("--- perm cluster test for old vs new ---")
    print("--- %s seconds ---" % (time.time() - start_time))
    print(cluster_p_values[cluster_p_values < 0.05]) # we keep 0.05
    
    
    # Cluster-Based Permutation test over 3 midfrontal channels and theta range - RQ2b
    channels = ["FC1", "FCz", "FC2"]
    spec_channel_list = []
    for i,channel in enumerate(channels):
        spec_channel_list.append(power_all_old[0].ch_names.index(channel))
    spec_channel_list
    
    start_time = time.time()
    T_obs, clusters, cluster_p_values, H0 = \
        mne.stats.permutation_cluster_test([power_all_old.data[:, spec_channel_list, 0:6,:], 
                                            power_all_old.data[:, spec_channel_list, 0:6,:]], 
        						           n_jobs = n_cores,
                                           n_permutations = n_perm, 
                                           threshold = threshold_tfce, 
                                           tail = 0, 
                                           buffer_size = 100, 
                                           verbose = "error", 
                                           seed = 888)
    print("--------------------")
    print("--- perm cluster test for old vs new ---")
    print("%s%s" % ("for channels: ", channels))
    print("--- %s seconds ---" % (time.time() - start_time))
    print(cluster_p_values[cluster_p_values < 0.05])
    
    # Cluster-Based Permutation test over posterior channels in alpha range - RQ2c
    channels = ["P7", "P5", "P3", "P1", "P2", "P4", "P6"]
    spec_channel_list = []
    for i,channel in enumerate(channels):
        spec_channel_list.append(power_all_old[0].ch_names.index(channel))
    spec_channel_list
    
    start_time = time.time()
    T_obs, clusters, cluster_p_values, H0 = \
        mne.stats.permutation_cluster_test([power_all_old.data[:, spec_channel_list, 5:10,:], 
                                            power_all_old.data[:, spec_channel_list, 5:10,:]],
                                           n_jobs = n_cores,
                                           n_permutations = n_perm, 
                                           threshold = threshold_tfce, 
                                           tail = 0, 
                                           buffer_size = 100, 
                                           verbose = "error",
                                           seed = 888)
    print("--------------------")
    print("--- perm cluster test for old vs new ---")
    print("%s%s" % ("for channels: ", channels))
    print("--- %s seconds ---" % (time.time() - start_time))
    print(cluster_p_values[cluster_p_values < 0.05])
    
