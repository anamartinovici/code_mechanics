#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
RQ1 - Group Analysis

Created on Sat Mar  5 13:19:53 2022

sources: 
    https://neuraldatascience.io/7-eeg/erp_group.html

@author: aschetti
'''

'''
import libraries
'''

import random
import mne
import numpy as np
import matplotlib.pyplot as plt
import glob
import re

'''
set parameters
'''

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/eeg_BIDS/' # directory with preprocessed files

filenames = glob.glob(preproc_path + '/*.fif') # list of .fif files

conditions = ['manmade', 'natural'] # condition names
sub_pattern = re.compile(r"\bsub-0\w*-\b") # regex pattern for plot titles 
topo_times = [0, 0.08, 0.125, 0.18] # time points for topographies
electrodes_graph = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2'] # region of interest for plots

'''
load preprocessed epoched data
'''

epochs = {} # preallocate array

for i in range(len(filenames)): # loop through files
    epochs[i] = mne.read_epochs(filenames[i], preload = False) # load data

'''
equalize epochs across conditions
'''

epochs_equal = {} # store equalized epochs
dropped_epochs = {} # dropped epochs per dataset

for i in range(len(filenames)):
    epochs_equal[i], dropped_epochs[i] = epochs[i].equalize_event_counts() # drop epochs from condition with more data
    # WE LOSE A LOT OF DATA! Double-check if this is still necessary after fixing preprocessing pipeline!

'''
create trial-averaged evoked data
'''

evoked_equal = {} # store trial-averaged evoked data

for i in range(len(filenames)):
    evoked_equal[i] = {c:epochs_equal[i][c].average() for c in conditions}       

'''
plots
'''  

# plot electrode montage
epochs_equal[1].plot_sensors(ch_type = 'eeg', show_names = True) 

# plot trial-averaged evoked data, separately for each participant and condition
for i in range(len(filenames)):
    {evoked_equal[i][c].plot_joint(times = topo_times, title = re.search(sub_pattern, filenames[i], flags = 0).group(0) + c) for c in conditions}

 
 
 
 
color_dict = {'manmade':'blue', 'natural':'red'}
linestyle_dict = {'manmade':'-', 'natural':'--'}

for i in range(len(filenames)):
    mne.viz.plot_compare_evokeds(evoked_equal[i],
                                 combine = 'mean',
                                 legend = 'lower right',
                                 picks = electrodes_graph, 
                                 show_sensors = 'upper right',
                                 colors = color_dict,
                                 linestyles = linestyle_dict,
                                 title = re.search(sub_pattern, filenames[i], flags = 0).group(0) + conditions[0] + '-' + conditions[1]
                                 )



############################################
########## FROM HERE #######################
############################################









epochs_equal[1].plot_sensors(ch_type = 'eeg', show_names = True) # show electrode montage

topo_times = [0, 0.08, 0.125, 0.18] # time points for topographies

# define region of interest
electrodes_graph = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2']

# color_dict = {'manmade':'blue', 'natural':'yellow'}
# linestyle_dict = {'manmade':'-', 'natural':'--'}

mne.viz.plot_compare_evokeds(evoked_equal[i],
                             combine = 'mean',
                             legend = 'lower right',
                             picks = electrodes_graph,
                             show_sensors = 'upper right',
                             # colors = color_dict,
                             # linestyles = linestyle_dict,
                             title = 'collapsed'
                            )

















'''
load preprocessed data
'''

preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/eeg_BIDS/' # directory with preprocessed files

filenames = glob.glob(preproc_path + '/*.fif') # list of .fif files

epochs = [mne.read_epochs(f, preload = False) for f in filenames]

channels = mne.pick_types(epochs[1].info, eeg = True, exclude = ['M1', 'M2', 'VEOG', 'HEOG']) # select scalp electrodes only

'''
modify data
'''

####### equalize epochs across conditions #######
epochs_equal = {}
dropped_epochs = {} # dropped epochs per dataset

for i in range(len(epochs)): # loop through files
    epochs_equal[i], dropped_epochs[i] = epochs[i].equalize_event_counts() # drop epochs from condition with more data
    # WE LOSE A LOT OF DATA! Double-check if this is still necessary after fixing preprocessing pipeline!

#################################################
















####### trial-averaged epochs #######
evoked_all = {} # collapsed across conditions
evoked_manmade = {} # manmade condition
evoked_natural = {} # natural condition
evoked_diff_manmade_natural = {} # difference between conditions

for j in range(len(epochs)):   
    evoked_all[j] = epochs_equal[j].average() # collapsed across conditions
    evoked_manmade[j] = epochs_equal[j]['manmade'].average() # manmade condition
    evoked_natural[j] = epochs_equal[j]['natural'].average() # natural condition
    evoked_diff_manmade_natural[j] = mne.combine_evoked([evoked_manmade[j], evoked_natural[j]], weights = [1, -1]) # difference between conditions

#################################################   

####### extract data from EEG channels only #######
evoked_data_all = {} # collapsed across conditions
evoked_data_manmade = {} # manmade condition
evoked_data_natural = {} # natural condition
evoked_data_diff_manmade_natural = {} # difference between conditions

for m in range(len(epochs)):
    evoked_data_all[m] = evoked_all[m].get_data(picks = channels)
    evoked_data_manmade[m] = evoked_manmade[m].get_data(picks = channels)
    evoked_data_natural[m] = evoked_natural[m].get_data(picks = channels)
    evoked_data_diff_manmade_natural[m] = evoked_diff_manmade_natural[m].get_data(picks = channels)

#################################################

# ####### grand-averages (collapsed across participants) #######

# list0 = evoked_data_all[0]
# list1 = evoked_data_all[1]
# list2 = evoked_data_all[2]
# list3 = evoked_data_all[3]
# list4 = evoked_data_all[4]
# list5 = evoked_data_all[5]
# list6 = evoked_data_all[6]
# list7 = evoked_data_all[7]
# list8 = evoked_data_all[8]
# list9 = evoked_data_all[9]
# list10 = evoked_data_all[10]
# list11 = evoked_data_all[11]
# list12 = evoked_data_all[12]
# list13 = evoked_data_all[13]
# list14 = evoked_data_all[14]
# list15 = evoked_data_all[15]
# list16 = evoked_data_all[16]
# list17 = evoked_data_all[17]
# list18 = evoked_data_all[18]
# list19 = evoked_data_all[19]
# list20 = evoked_data_all[20]
# list21 = evoked_data_all[21]
# list22 = evoked_data_all[22]
# list23 = evoked_data_all[23]
# list24 = evoked_data_all[24]
# list25 = evoked_data_all[25]
# list26 = evoked_data_all[26]
# list27 = evoked_data_all[27]
# list28 = evoked_data_all[28]
# list29 = evoked_data_all[29]
# list30 = evoked_data_all[30]
# list31 = evoked_data_all[31]
# list32 = evoked_data_all[32]

# product = np.multiply(list0, list1, list2, list3, list4, list5, list6, list7, list8, list9, list10, list11, list12, list13, list14, list15, list16, list17, list18, list19, list20, list21, list22, list23, list24, list25, list26, list27, list28, list29, list30, list31, list32)

# print(product)

# grandavg_all = {} # collapsed across conditions
# grandavg_manmade = {} # manmade condition
# grandavg_natural = {} # natural condition

# for n in range(len(epochs)):
#     grandavg_all[n] = np.mean(evoked_data_all[n], axis = 1) #
#     grandavg_manmade[n] = np.mean(epochs_equal_data
#     grandavg_natural[n] = np.mean(
   
# #################################################
   
'''
visualization
'''

epochs_equal[1].plot_sensors(ch_type = 'eeg', show_names = True) # show electrode montage

topo_times = [0, 0.08, 0.125, 0.18] # time points for topographies

# define region of interest
electrodes_graph = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2']

color_dict = {'manmade':'blue', 'natural':'yellow'}
linestyle_dict = {'manmade':'-', 'natural':'--'}

mne.viz.plot_compare_evokeds(evoked_data_manmade | evoked_data_natural,
                             combine = 'mean',
                             legend = 'lower right',
                             picks = electrodes_graph,
                             show_sensors = 'upper right',
                             colors = color_dict,
                             linestyles = linestyle_dict,
                             title = 'manmade vs. natural'
                            )

plt.show()









butterfly_topomap_all_evoked = all_evoked.plot_joint(title = 'all epochs', times = topo_times) # all conditions

butterfly_topomap_evoked_manmade = evoked_manmade.plot_joint(title = 'manmade', times = topo_times) # `manmade`
butterfly_topomap_evoked_natural = evoked_natural.plot_joint(title = 'natural', times = topo_times) # `natural`

butterfly_topomap_diff_manmade_natural_evoked = diff_manmade_natural_evoked.plot_joint(title = 'condition difference', times = topo_times) # difference between conditions


    
    

    
'''
compare evoked waveforms
'''










    
    
  
    
    
    
    

channels = [mne.pick_types(epochs, eeg = True, exclude = ['M1', 'M2', 'VEOG', 'HEOG']) for f in filenames] # pick scalp electrodes only





# # ensure equal epoch number across conditions
# epochs, dropped_epochs = [epochs.equalize_event_counts(conditions) for f in filenames]


epochs, dropped_epochs = [epochs.equalize_event_counts(conditions) for f in filenames]


epochs_data = epochs.get_data(picks = channels) # select data from scalp electrodes only

'''
compare evoked waveforms
'''

evoked = epochs[conditions].average()

# define region of interest
electrodes_graph = ['P9', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'P10', 'PO7', 'PO3', 'O1', 'POz', 'Oz', 'Iz', 'PO4', 'PO8', 'O2']

color_dict = {'manmade':'blue', 'natural':'yellow'}
linestyle_dict = {'manmade':'-', 'natural':'--'}

mne.viz.plot_compare_evokeds(evoked,
                             combine = 'mean',
                             legend = 'lower right',
                             picks = electrodes_graph,
                             show_sensors = 'upper right',
                             colors = color_dict,
                             linestyles = linestyle_dict,
                             title = 'manmade vs. natural'
                            )
plt.show()


# Define plot parameters
roi = ['C3', 'Cz', 'C4', 
       'P3', 'Pz', 'P4']

color_dict = {'Control':'blue', 'Violation':'red'}
linestyle_dict = {'Control':'-', 'Violation':'--'}


mne.viz.plot_compare_evokeds(evokeds,
                             combine='mean',
                             legend='lower right',
                             picks=roi, show_sensors='upper right',
                             colors=color_dict,
                             linestyles=linestyle_dict,
                             title='Violation vs. Control Waveforms'
                            )
plt.show()