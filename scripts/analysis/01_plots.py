#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RQ1 - Plots


@author: aschetti
"""

# %% IMPORT LIBRARIES

import random
import numpy as np
import glob
import os
import matplotlib.pyplot as plt
import mne

from os.path import join as opj

# %% SETUP

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

# directories
preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/data/processed_data/ERP/' # directory with preprocessed files

# define electrode montage
montage = mne.channels.make_standard_montage("biosemi64")

filenames = glob.glob(preproc_path + '/**/*.fif') # list of .fif files in directory

# region of interest for plots
electrodes_graph = ['PO7', 'PO3', 'O1', 
                    'PO4', 'PO8', 'O2',
                    'POz', 'Oz', 'Iz']
                    
topo_times = np.arange(0, 0.5, 0.05) # time points for topographies

# time window for collapsed localizer
t_min_localizer = 0
t_max_localizer = 0.5

# time window for statistical analysis
t_min = 0
t_max = 0.3

# # TFCE (threshold-free cluster enhancement)
# # https://mne.tools/stable/auto_tutorials/stats-sensor-space/20_erp_stats.html?highlight=cluster%20enhancement
# tfce_params = dict(start = .2, step = .2) # parameter values
# n_perm = 5000 # number of permutations (at least 1000)

# plot parameters
time_unit = dict(time_unit = "s") # time unit

# %% data cleaning (one dataset)

# get all participant names
subs = [name for name in os.listdir(preproc_path) if name.startswith('sub')] 


for ssj in subs:


    # message in console
    print("---------------------------")
    print("--- load epochs " + ssj + " ---")
    print("---------------------------")
      
    # load 'manmade' epochs
    epochs_manmade = mne.read_epochs(
        opj(preproc_path + ssj, ssj + '_manmade_epo.fif'), preload = True).pick_types(
            eeg = True, 
            exclude = ['M1', 'M2', 'VEOG', 'HEOG'] # select scalp electrodes only
            )
        
    # load 'natural' epochs
    epochs_natural = mne.read_epochs(
        opj(preproc_path + ssj, ssj + '_natural_epo.fif'), preload = True).pick_types(
            eeg = True, 
            exclude = ['M1', 'M2', 'VEOG', 'HEOG'] # select scalp electrodes only
            )
    
    # %% create condition-specific evoked responses
    
    # evoked responses (weighted average)
    evoked_manmade = epochs_manmade.average() # 'manmade' condition
    evoked_natural = epochs_natural.average() # 'natural' condition
        
    # trial-averaged evoked responses with confidence intervals
    evokeds = dict(manmade = list(epochs_manmade.iter_evoked()), # 'manmade' condition
                   natural = list(epochs_natural.iter_evoked())) # 'natural' condition
    
    # %% visualize condition-specific evoked responses

    # # plot electrode montage
    # epochs_manmade.plot_sensors(ch_type = 'eeg', show_names = True) 

    # joint plots (butterfly + topography)
    evoked_manmade.plot_joint(times = topo_times, title = opj(ssj + '_manmade')) # 'manmade' condition
    evoked_natural.plot_joint(times = topo_times, title = opj(ssj + '_natural')) # 'natural' condition

    # comparing conditions
    mne.viz.plot_compare_evokeds(evokeds, 
                                 combine = 'mean',
                                 legend = 'lower left',
                                 picks = electrodes_graph,
                                 show_sensors = 'upper left',
                                 title = opj(ssj + '_manmade-minus-natural')
                                 )    
      
    # %% create grand-averaged epochs (collapsed across conditions)
    #    for data-driven identification of N1 electrodes and time window
    #    (collapsed localizer)
    
    # grand average (weighted average)
    evoked_grand_average = mne.combine_evoked([evoked_manmade, evoked_natural], weights = 'nave')
   
    # joint plot (butterfly + topography)
    evoked_grand_average.plot_joint(times = topo_times, title = opj(ssj + '_localizer')) # collapsed localizer
    
    # localizer ERP
    mne.viz.plot_compare_evokeds(evoked_grand_average, 
                                 combine = 'mean',
                                 legend = None,
                                 picks = electrodes_graph,
                                 show_sensors = 'upper left',                                
                                 title = opj(ssj + '_localizer')
                                 )
       
    # %% stats (one dataset)
    # TFCE
    
    # calculate adjacency matrix between sensors from their locations
    adjacency, _ = find_ch_adjacency(epochs_manmade.info, "eeg")

    # extract data from all scalp electrodes and time points (excluding baseline)
    # transpose because the cluster test requires channels to be last
    # here inference is done over items, but later it will be done over participants
    localizer_data = np.concatenate( # concatenate condition-specific epochs
        (epochs_manmade.get_data(picks = 'eeg', tmin = t_min_localizer, tmax = t_max_localizer), 
         epochs_natural.get_data(picks = 'eeg', tmin = t_min_localizer, tmax = t_max_localizer))
        )
    localizer_zeros = np.zeros(localizer_data.shape) # array of zeros with same dimensions as localizer data

    # transpose (each array dimension should be observations × time × space) and merge in one array
    localizer_TFCE = [localizer_data.transpose(0, 2, 1), 
                      localizer_zeros.transpose(0, 2, 1)]    
    
    # calculate statistical thresholds
    t_obs, clusters, cluster_pv, h0 = spatio_temporal_cluster_test(
        localizer_TFCE, 
        threshold = tfce_params, 
        n_permutations = n_perm, 
        tail = 0, 
        adjacency = adjacency,
        seed = project_seed, 
        out_type = 'indices', 
        check_disjoint = False
        )    
    
    # extract statistically significant time points
    significant_time_points = cluster_pv.reshape(t_obs.shape).T < .05
    
    
    
    
    # extract statistically significant electrodes
    
    
    
    
    
    
    
    # artificially create epochs of localizer 
    localizer_epochs = mne.EpochsArray(
        localizer_data, 
        mne.create_info( # create info structure
            evoked_grand_average.ch_names, # use channel names of grand average
            epochs_manmade.info['sfreq'], # sampling rate (can be extracted from any epoch file)
            ch_types = ['eeg'] * len(evoked_grand_average.ch_names) # repeat 'eeg' for as many channels as available
            )
        )
    
    # add montage for topographies
    localizer_epochs.info.set_montage('biosemi64')
    
    # evoked responses
    localizer_evoked = localizer_epochs.average()
        
    # visualize the results
    localizer_evoked.plot_image(
        mask = significant_time_points, 
        show_names = "all", 
        titles =  opj(ssj + '_localizer')
        )   
    
    # joint plot (butterfly + topography)
    localizer_evoked.plot_joint(        
        times = topo_times,
        ts_args = time_unit,
        topomap_args = time_unit,
        title = opj(ssj + '_localizer')        
        )
    
    
    
    
    
    
    
    # Visualize
    ## <string>:1: RuntimeWarning: Ignoring argument "tail", performing 1-tailed F-test
    fig, (ax0, ax1, ax2) = plt.subplots(nrows=3, ncols=1, sharex=True)
    
    times = epochs.times
    ax0.axvline(x=0, linestyle="--", color="black")
    ## <matplotlib.lines.Line2D object at 0x00000000BFAE7640>
    ax0.plot(times, np.mean(condition1, axis=0), label="Audio")
    ## [<matplotlib.lines.Line2D object at 0x00000000BFAF3D30>]
    ax0.plot(times, np.mean(condition2, axis=0), label="Visual")
    ## [<matplotlib.lines.Line2D object at 0x00000000BFAF3F40>]
    ax0.legend(loc="upper right")
    ## <matplotlib.legend.Legend object at 0x00000000BFAF3EE0>
    ax0.set_ylabel("uV")
    
    # Difference
    ax1.axvline(x=0, linestyle="--", color="black")
    ax1.plot(times, condition1.mean(axis=0) - condition2.mean(axis=0))
    ## [<matplotlib.lines.Line2D object at 0x00000000BFB07B20>]
    ax1.axhline(y=0, linestyle="--", color="black")
    ## <matplotlib.lines.Line2D object at 0x00000000BFB07CD0>
    ax1.set_ylabel("Difference")
    
    # T-values
    ax2.axvline(x=0, linestyle="--", color="black")
    h = None
    for i, c in enumerate(clusters):
        c = c[0]
        if p_vals[i] <= 0.05:
            h = ax2.axvspan(times[c.start],
                            times[c.stop - 1],
                            color='red',
                            alpha=0.5)
        else:
            ax2.axvspan(times[c.start],
                        times[c.stop - 1],
                        color=(0.3, 0.3, 0.3),
                        alpha=0.3)
                ## <matplotlib.patches.Polygon object at 0x00000000BFB16550>
                ## <matplotlib.patches.Polygon object at 0x00000000BFB16BE0>
        hf = ax2.plot(times, t_vals, 'g')
        if h is not None:
            plt.legend((h, ), ('cluster p-value < 0.05', ))
                    ## <matplotlib.legend.Legend object at 0x00000000BFB16D00>
            plt.xlabel("time (ms)")
                    ## Text(0.5, 0, 'time (ms)')
            plt.ylabel("t-values")
                    ## Text(0, 0.5, 't-values')
            plt.savefig("figures/fig2.png")
            plt.clf()
                    
                    
    
    
    
    # # Create ROIs by checking channel labels
    # selections = make_1020_channel_selections(evoked.info, midline="12z")
    
    # # Visualize the results
    # fig, axes = plt.subplots(nrows=3, figsize=(8, 8))
    # axes = {sel: ax for sel, ax in zip(selections, axes.ravel())}
    # evoked.plot_image(axes=axes, group_by=selections, colorbar=False, show=False,
    #                   mask=significant_points, show_names="all", titles=None,
    #                   **time_unit)
    # plt.colorbar(axes["Left"].images[-1], ax=list(axes.values()), shrink=.3,
    #              label="µV")
    
    # plt.show()





            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
    
    # %% data visualization (one dataset)

    # plot electrode montage
    epochs_manmade.plot_sensors(ch_type = 'eeg', show_names = True) 

    # joint plots (butterfly + topography)
    evoked_manmade.plot_joint(times = topo_times, title = opj(ssj + '_manmade')) # 'manmade' condition
    evoked_natural.plot_joint(times = topo_times, title = opj(ssj + '_natural')) # 'natural' condition

    # comparing conditions
    mne.viz.plot_compare_evokeds(evokeds, 
                                 combine = 'mean',
                                 legend = 'lower left',
                                 picks = electrodes_graph,
                                 show_sensors = 'upper left',
                                 colors = color_dict,
                                 linestyles = linestyle_dict,
                                 title = opj(ssj + '_manmade-minus-natural')
                                 )

    # # difference wave
    # manmade_minus_natural = mne.combine_evoked([evoked_equal_manmade, evoked_equal_natural], weights = [1, -1])
    # manmade_minus_natural.plot_joint(times = topo_times, title = re.search(sub_pattern, filenames[0], flags = 0).group(0) + conditions[1])

    # # grand average
    # evoked_grand_average = mne.grand_average([evoked_manmade, evoked_natural])        
    
    # %% stats (one dataset)
    # TFCE (threshold-free cluster enhancement)
    # https://mne.tools/stable/auto_tutorials/stats-sensor-space/20_erp_stats.html?highlight=cluster%20enhancement

    # calculate adjacency matrix between sensors from their locations
    adjacency, _ = find_ch_adjacency(epochs_manmade.info, "eeg")

    # extract only time window of interest
    epochs_manmade_stats = epochs_manmade.crop(t_min, t_max)#, include_tmax = False) # 'manmade' condition
    epochs_natural_stats = epochs_natural.crop(t_min, t_max)#, include_tmax = False) # 'natural' condition
    
    # extract data from scalp electrodes and selected time window
    # transpose because the cluster test requires channels to be last
    # In this case, inference is done over items. In the same manner, we could
    # also conduct the test over, e.g., subjects.
    epochs_TFCE = [epochs_manmade_stats.get_data(picks = 'eeg').transpose(0, 2, 1),
                   epochs_natural_stats.get_data(picks = 'eeg').transpose(0, 2, 1)]

    # tfce = dict(start = .4, step = .4) # ideally start and step would be smaller
    tfce = dict(start = .2, step = .2)

    n_perm = 5000 # number of permutations (at least 1000)

    # Calculate statistical thresholds
    t_obs, clusters, cluster_pv, h0 = spatio_temporal_cluster_test(
        epochs_TFCE, 
        threshold = tfce, 
        n_permutations = n_perm, 
        tail = 0, 
        adjacency = adjacency,
        seed = project_seed, 
        out_type = 'indices', 
        check_disjoint = False
        )

    significant_points = cluster_pv.reshape(t_obs.shape).T < .05
    # print(str(significant_points.sum()) + " points selected by TFCE ...")

    # calculate difference wave on which to plot statistically different points
    evoked = mne.combine_evoked(
                                [epochs_manmade_stats.average(), 
                                epochs_natural_stats.average()],
                                weights = 'nave'
                                )

    # Visualize the results
    evoked.plot_image(
        mask = significant_points, 
        show_names = "all", 
        titles =  opj(ssj + '_manmade-minus-natural')
        )











'''
ERP analysis using MNE-Python
https://neurokit2.readthedocs.io/en/dev/studies/erp_gam.html
'''

epochs_equal_manmade = epochs_equal['manmade']
epochs_equal_natural = epochs_equal['natural']


# Transform each condition to array
condition1 = np.mean(epochs["audio"].get_data(), axis=1)
condition2 = np.mean(epochs["visual"].get_data(), axis=1)

# Permutation test to find significant cluster of differences
t_vals, clusters, p_vals, h0 = mne.stats.permutation_cluster_test([condition1, condition2], out_type='mask', seed=111)

# Visualize
## <string>:1: RuntimeWarning: Ignoring argument "tail", performing 1-tailed F-test
fig, (ax0, ax1, ax2) = plt.subplots(nrows=3, ncols=1, sharex=True)

times = epochs.times
ax0.axvline(x=0, linestyle="--", color="black")
## <matplotlib.lines.Line2D object at 0x00000000BFAE7640>
ax0.plot(times, np.mean(condition1, axis=0), label="Audio")
## [<matplotlib.lines.Line2D object at 0x00000000BFAF3D30>]
ax0.plot(times, np.mean(condition2, axis=0), label="Visual")
## [<matplotlib.lines.Line2D object at 0x00000000BFAF3F40>]
ax0.legend(loc="upper right")
## <matplotlib.legend.Legend object at 0x00000000BFAF3EE0>
ax0.set_ylabel("uV")

# Difference
ax1.axvline(x=0, linestyle="--", color="black")
ax1.plot(times, condition1.mean(axis=0) - condition2.mean(axis=0))
## [<matplotlib.lines.Line2D object at 0x00000000BFB07B20>]
ax1.axhline(y=0, linestyle="--", color="black")
## <matplotlib.lines.Line2D object at 0x00000000BFB07CD0>
ax1.set_ylabel("Difference")

# T-values
ax2.axvline(x=0, linestyle="--", color="black")
h = None
for i, c in enumerate(clusters):
    c = c[0]
    if p_vals[i] <= 0.05:
        h = ax2.axvspan(times[c.start],
                        times[c.stop - 1],
                        color='red',
                        alpha=0.5)
    else:
        ax2.axvspan(times[c.start],
                    times[c.stop - 1],
                    color=(0.3, 0.3, 0.3),
                    alpha=0.3)
## <matplotlib.patches.Polygon object at 0x00000000BFB16550>
## <matplotlib.patches.Polygon object at 0x00000000BFB16BE0>
hf = ax2.plot(times, t_vals, 'g')
if h is not None:
    plt.legend((h, ), ('cluster p-value < 0.05', ))
## <matplotlib.legend.Legend object at 0x00000000BFB16D00>
plt.xlabel("time (ms)")
## Text(0.5, 0, 'time (ms)')
plt.ylabel("t-values")
## Text(0, 0.5, 't-values')
plt.savefig("figures/fig2.png")
plt.clf()

























'''
old code
'''

# preallocate arrays
epochs = {} # epochs
epochs_equal = {} # equalized epochs
dropped_epochs = {} # dropped epochs per dataset
# evoked_equal = {} # trial-averaged evoked data
evoked_equal_manmade = {} # trial-averaged evoked data ('manmade' condition)
evoked_equal_natural = {} # trial-averaged evoked data ('natural' condition)




evoked_grand_average = {} # grand-averaged evoked data

for i in range(len(filenames)): # loop through files
    epochs[i] = mne.read_epochs(filenames[i], preload = False) # load data (preload  = False or python will crash on my coomputer)
    epochs_equal[i], dropped_epochs[i] = epochs[i].equalize_event_counts() # equalize epochs across conditions (drop epochs from condition with more data)
    
    
    evoked_equal_manmade[i] = epochs_equal[i]['manmade'].average()
    evoked_equal_natural[i] = epochs_equal[i]['natural'].average()
    
    evokeds[i] = dict(manmade = evoked_equal_manmade[i].iter_evoked()), natural = evoked_equal_natural[i].iter_evoked())))
    
    
    
    # evoked_equal[i] = {c:epochs_equal[i][c].average() for c in conditions} # create trial-averaged evoked data
    
    # # plot trial-averaged evoked data, separately for each condition
    # {evoked_equal[i][c].plot_joint(times = topo_times, title = re.search(sub_pattern, filenames[i], flags = 0).group(0) + c) for c in conditions}  
    # confidence intervals
    # evoked_equal[i] = dict(manmade = list(epochs_equal[i]['manmade'].iter_evoked()),
    #                     natural = list(epochs_equal[i]['natural'].iter_evoked()))  
    # # compare plot
    # mne.viz.plot_compare_evokeds(evoked_equal[i],
    #                              combine = 'mean',
    #                              legend = 'lower left',
    #                              picks = electrodes_graph, 
    #                              show_sensors = 'upper left',
    #                              colors = color_dict,
    #                              linestyles = linestyle_dict,
    #                              title = re.search(sub_pattern, filenames[i], flags = 0).group(0) + conditions[0] + '-' + conditions[1]
    #                              )
    evoked_grand_average[i] = mne.grand_average(evoked_equal[i])






evokeds = {}


for i in range(len(filenames)):
    # confidence intervals
    evokeds[i] = dict(manmade = evoked_equal_manmade[i].iter_evoked()), natural = evoked_equal_natural[i].iter_evoked())))
    mne.viz.plot_compare_evokeds(evokeds[i],
                              combine = 'mean',
                              legend = 'lower left',
                              picks = electrodes_graph, 
                              show_sensors = 'upper left',
                              colors = color_dict,
                              linestyles = linestyle_dict,
                              title = re.search(sub_pattern, filenames[i], flags = 0).group(0) + conditions[0] + '-' + conditions[1]
                              )





evoked_grand_average = {} # grand-averaged evoked data


evoked_grand_average[i] = mne.grand_average(evoked_equal[i])
print(grand_average[i])





# plot electrode montage
epochs_equal[2].plot_sensors(ch_type = 'eeg', show_names = True) 








for i in range(len(filenames)): # loop through files
    epochs[i] = mne.read_epochs(filenames[i], preload = False) # load data (preload  = False or python will crash on my coomputer)
    epochs_equal[i], dropped_epochs[i] = epochs[i].equalize_event_counts() # equalize epochs across conditions (drop epochs from condition with more data)
    evoked_equal[i] = {c:epochs_equal[i][c].average() for c in conditions} # create trial-averaged evoked data
    # # plot trial-averaged evoked data, separately for each condition
    # {evoked_equal[i][c].plot_joint(times = topo_times, title = re.search(sub_pattern, filenames[i], flags = 0).group(0) + c) for c in conditions}  
    # confidence intervals around trial-averaged evoked data
    evoked_equal[i] = dict(manmade = list(epochs_equal[i]['manmade'].iter_evoked()),
                        natural = list(epochs_equal[i]['natural'].iter_evoked()))  
    # compare plot
    mne.viz.plot_compare_evokeds(evoked_equal[i],
                                 combine = 'mean',
                                 legend = 'lower left',
                                 picks = electrodes_graph, 
                                 show_sensors = 'upper left',
                                 colors = color_dict,
                                 linestyles = linestyle_dict,
                                 title = re.search(sub_pattern, filenames[i], flags = 0).group(0) + conditions[0] + '-' + conditions[1]
                                 )














  # # load data (for debugging only)
    # epochs_clean = mne.read_epochs(
    #     opj(preproc_path, ssj + '_epochs_AutoReject.fif'),
    #     preload = True
    #     )