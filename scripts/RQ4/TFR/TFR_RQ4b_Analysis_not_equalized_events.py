def f_TFR_RQ4b_analysis_NOTeq(project_seed, path_to_TFR_step1_output, path_to_TFR_RQ4_output, path_to_cache_dir):
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
    epochs_old_hit = mne.read_epochs(glob(opj(path_to_TFR_step1_output, subject, subject + "*remembered*epo.fif"))[0],
                                     preload = True,
                                     verbose = "error")
    
    times = epochs_old_hit.crop(0, 0.5).decimate(decim).times
    epochs_old_hit.pick_types(eeg = True)
    info = epochs_old_hit.info
    logged_freqs = np.logspace(np.log10(4), np.log10(40), 18)
    
    power_all_subj_rem = np.load(opj(path_to_TFR_RQ4_output, "not_equalized", "power_all_subj_rem.npy"))
    power_all_subj_forg = np.load(opj(path_to_TFR_RQ4_output, "not_equalized", "power_all_subj_forg.npy"))
    
    power_all_subj_rem = mne.time_frequency.EpochsTFR(info, power_all_subj_rem, times, logged_freqs)
    power_all_subj_forg = mne.time_frequency.EpochsTFR(info, power_all_subj_forg, times, logged_freqs)
    
    stat_old_hit_vs_miss, pval_old_hit_vs_miss = ttest_ind(power_all_subj_rem.data,
                                                           power_all_subj_forg.data,
                                                           axis = 0,
                                                           equal_var = False, 
                                                           nan_policy = "propagate")
    
    # take only the freqs from 4-8HZ
    OldHitVsOldMiss = mne.time_frequency.AverageTFR(power_all_subj_rem.info,
                                                    stat_old_hit_vs_miss,
                                                    power_all_subj_rem.times,
                                                    power_all_subj_rem.freqs,
                                                    nave = power_all_subj_rem.data.shape[0]) 
    
    # take 0.3s to 0.5s after stim onset
    mne.viz.plot_tfr_topomap(OldHitVsOldMiss,
                             colorbar = False, 
                             size = 10, 
                             show_names = False, 
                             unit = None,  
                             cbar_fmt = "%1.2f") 

    # Cluster-Based Permutation test over all channels and freqs
    mne.set_cache_dir(path_to_cache_dir)
    threshold_tfce = dict(start = 0, step = 0.2)
    
    n_j = 4
    n_perm = 100
    
    print("%s%s" % ("starting at: ", time.time()))
    print("%s%s" % ("number of cores: ", n_j))
    print("%s%s" % ("number of permutations: ", n_perm))
    
    start_time = time.time()
    T_obs, clusters, cluster_p_values, H0 = \
        mne.stats.permutation_cluster_test([power_all_subj_rem.data, 
                                            power_all_subj_forg.data],
                                           n_jobs = n_j,
                                           n_permutations = n_perm,
                                           threshold = threshold_tfce,
                                           tail = 0, 
                                           buffer_size = 100,
                                           verbose = "error", 
                                           seed = 888)
    print("--- %s seconds ---" % (time.time() - start_time))
    print(cluster_p_values[cluster_p_values < 0.05])
    
