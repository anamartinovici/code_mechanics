def f_TFR_RQ3b_analysis_eq(project_seed, path_to_TFR_step1_output, path_to_TFR_RQ3_output, path_to_cache_dir):
    import mne
    import random
    import time
    
    import numpy as np
    
    from os.path import join as opj
    from glob import glob
    from scipy.stats import ttest_ind
    
    # set seed to ensure computational reproducibility
    random.seed(project_seed) 
    
    decim = 1 
    subject = "sub-001"
    epochs_old_hit = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*old_hit*epo.fif"))[0],
                                     preload = True,
                                     verbose = "error")
    
    times = epochs_old_hit.crop(0, 0.5).decimate(decim).times
    epochs_old_hit.pick_types(eeg = True)
    info = epochs_old_hit.info
    logged_freqs = np.logspace(np.log10(4), np.log10(40), 18)
    
    power_all_subj_old_hit = np.load(opj(path_to_TFR_RQ3_output, "equalized", "power_all_subj_old_hit.npy"))
    power_all_subj_old_miss = np.load(opj(path_to_TFR_RQ3_output, "equalized", "power_all_subj_old_miss.npy"))
    
    power_all_subj_old_hit = mne.time_frequency.EpochsTFR(info, power_all_subj_old_hit, times, logged_freqs)
    power_all_subj_old_miss = mne.time_frequency.EpochsTFR(info, power_all_subj_old_miss, times, logged_freqs)
    
    stat_old_hit_vs_miss, pval_old_hit_vs_miss = ttest_ind(power_all_subj_old_hit.data,
                                                           power_all_subj_old_miss.data, 
                                                           axis = 0, 
                                                           equal_var = False, 
                                                           nan_policy = "propagate")
    
    # take only the freqs from 4-8HZ
    OldHitVsOldMiss = mne.time_frequency.AverageTFR(power_all_subj_old_hit.info, 
                                                    stat_old_hit_vs_miss, 
                                                    power_all_subj_old_hit.times, 
                                                    power_all_subj_old_hit.freqs, 
                                                    nave = power_all_subj_old_hit.data.shape[0])
    
    # take 0.3s to 0.5s after stim onset
    mne.viz.plot_tfr_topomap(OldHitVsOldMiss, 
                             colorbar = False, 
                             size = 10, 
                             show_names = False, 
                             unit = None,
                             cbar_fmt = "%1.2f")
    
    # Cluster-Based Permutation test over all channels and freqs
    print(path_to_cache_dir)
    mne.set_cache_dir(path_to_cache_dir)
    threshold_tfce = dict(start = 0, step = 0.2)
    
    start_time = time.time()
    T_obs, clusters, cluster_p_values, H0 = \
        mne.stats.permutation_cluster_test([power_all_subj_old_hit.data, power_all_subj_old_miss.data],
                                           n_jobs = 4,
                                           n_permutations = 1000,
                                           threshold = threshold_tfce,
                                           tail = 0, 
                                           buffer_size = 1000,
                                           verbose = "error", 
                                           seed = 888)
    
    print("--- %s seconds ---" % (time.time() - start_time))
    print(cluster_p_values[cluster_p_values < 0.05])
    
