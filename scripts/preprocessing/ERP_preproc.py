#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
Preprocessing of raw data for ERP analysis 

sources: 
    https://neuraldatascience.io/7-eeg/erp_group.html
    https://mne.tools/stable/auto_tutorials/evoked/30_eeg_erp.html#sphx-glr-auto-tutorials-evoked-30-eeg-erp-py
    https://mne.tools/stable/auto_tutorials/stats-sensor-space/20_erp_stats.html#sphx-glr-auto-tutorials-stats-sensor-space-20-erp-stats-py

@author: Antonio Schettino
'''

'''
import libraries
'''

import random
import numpy as np
# import glob
# import re
# import matplotlib.pyplot as plt
import os
import mne
# import time

from os.path import join as opj
from mne_bids import BIDSPath, read_raw_bids
# from mne_bids import BIDSPath, read_raw_bids, print_dir_tree, make_report
# from pyprep import NoisyChannels
# from mne.preprocessing import ICA, create_eog_epochs, create_ecg_epochs, corrmap
# from autoreject import AutoReject

'''
setup
'''

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

raw_path = '/home/aschetti/Documents/Projects/code_mechanics/data/raw/eeg_BIDS/' # directory with raw data
# preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/eeg_BIDS/' # directory with preprocessed files

# filenames = glob.glob(preproc_path + '/*.fif') # list of .fif files in directory

conditions = ['manmade', 'natural'] # condition names

datatype = 'eeg'

# # plot parameters
# sub_pattern = re.compile(r"\bsub-0\w*-\b") # regex pattern for plot titles 

# define electrode montage
montage = mne.channels.make_standard_montage("biosemi64")
# montage.plot() # visualize montage

# filter cutoffs
cutoff_lowpass = 0.1
cutoff_highpass = 40
# cutoff_h = None # we also get rid of anything higher than 100Hz which is typically not of relevance to human studies

# referencing method
reference = 'average'

'''
preprocessing
'''

# get all subject numbers
subs = [ name for name in os.listdir(raw_path) if name.startswith('sub') ] 

for ssj in subs[:1]:
    
    print(ssj)
    
    # create BIDS path
    bids_path = BIDSPath(
        subject = ssj[-3:], # subject identifier (remove 'sub-' because '-' is not allowed as character)
        session = None, # acquisition session: not specified
        task = 'xxxx', # task name
        acquisition = None, # acquisition parameters: not specified
        run = None, # run number: not specified
        processing = None, # processing label: not specified
        recording = None, # recording name: not specified
        space = None, # coordinate space (for anatomical and sensor location): not specified
        split = None, # split of continuous recording file: not specified
        suffix = datatype, # filename suffix
        extension = None, # file extension: not specified
        datatype = datatype, # BIDS data type        
        root = raw_path, # directory of BIDS dataset
        check = True # BIDS conformity
        )    
    
    # load data
    raw = mne.io.read_raw_brainvision(
        bids_path, 
        eog = ('VEOG', 'HEOG','IO1','IO2','Afp9','Afp10'), # ocular channels
        misc = ('M1','M2'), # mastoid channels
        preload = True
        )        
    
    # check data info    
    print(raw.info)
    
    # assign electrode montage
    raw = raw.set_montage(montage)
        
    # create backup copy of raw data
    raw_backup = raw.copy()    
    
    # filter data
    raw_filt = raw.filter( # apply high-pass filter, then apply low-pass filter
        l_freq = cutoff_lowpass, 
        h_freq = None).filter( # apply low-pass filter
            l_freq = None,
            h_freq = cutoff_highpass
            )
    
    # plot filtered data
    raw_filt.plot(
        duration = 20, # time window (in seconds)
        start = 20, # start time (in seconds)
        n_channels = len(raw.ch_names), # number of channels to plot
        color = 'darkblue', # line color
        bad_color = 'red', # line color: bad channels
        title = 'Low- and high-pass filtered EEG', # plot title
        remove_dc = True, # remove DC component (visualization only)
        proj = False, # apply projectors prior to plotting
        group_by = 'type', # group by channel type
        butterfly = False # butterfly mode        
        )
 
    
    

    
    
    
    
    

    
    # Find noisy channels
    nd = NoisyChannels(raw_notch)
    nd.find_all_bads(ransac=False) 
    bads = nd.get_bads(verbose=True)
    
    
    
    # downsample
    
    
    



    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    bids_path = BIDSPath(subject = subject[-3:], task = 'xxxx',suffix = suffix,
                          datatype = datatype, root = raw_path)
    
    raw = mne.io.read_raw_brainvision(bids_path, eog=('VEOG', 'HEOG','IO1','IO2','Afp9','Afp10'), misc=('M1','M2'), scale=1.0, preload=True, verbose=False)


    montage = mne.channels.make_standard_montage("biosemi64")
    montage.plot()
    raw.set_montage(montage)

    sample_rate = raw.info["sfreq"]

    raw_copy = raw.copy()


    start = time.time()

    # Filtering
    raw_highpass = raw.copy().filter(l_freq=cutoff_l, h_freq=None) # apply the filter
    
    #specify the line noise frequencies
    freqs=np.arange(50, sample_rate/2, 50) # specify frequencies to remove
    
    # Power Line Noise Removal
    raw_notch = raw_highpass.copy().notch_filter(freqs=freqs) # apply a notch filter to remove frequencies

    # Find noisy channels
    nd = NoisyChannels(raw_notch)
    nd.find_all_bads(ransac=False) 
    bads = nd.get_bads(verbose=True)
    
    # add the bad channel info 
    raw_notch.info['bads']=bads    
    
    # Interpolating bad channels
    eeg_data_interp = raw_notch.copy()#.pick_types(eeg=True, exclude=[])
    eeg_data_interp.interpolate_bads(reset_bads=True)


    # referencing
    if reference=='average':
        eeg_data_interp_ref = eeg_data_interp.copy().set_eeg_reference(ref_channels='average')
    elif reference=='mastoid':
        eeg_data_interp_ref = eeg_data_interp.copy().set_eeg_reference(ref_channels=['EXG5','EXG6'])

    
    #save stuff
    prepro_dir = opj(bids_root,'Preprocessed_MNE',subject)
    ensure_dir(prepro_dir)
    
    #Detailed bad channels in each criteria before robust reference.
    with open(opj(prepro_dir,subject+'_bad_channels.txt'), 'w') as f:
        for item in bads:
            f.write("%s\n" % item)



    
    # save preprocessed data
    eeg_data_interp_ref.save(opj(prepro_dir,subject+'_task_after_pyprep_raw.fif'), overwrite = True)
    
    

    #-- ICA --- #

    ica = mne.preprocessing.ICA(n_components=40, random_state=1, allow_ref_meg=True)


    ica.fit(eeg_data_interp_ref)

    ica.exclude = []    

    # find which ICs match the EOG pattern
    eog_indices_veog, eog_scores_veog = ica.find_bads_eog(eeg_data_interp_ref, ch_name='VEOG')

    eog_indices_hoeg, eog_scores_heog = ica.find_bads_eog(eeg_data_interp_ref, ch_name='HEOG')

    # get the union of the components detected from the two different channels
    union_indices_eog = list(set(eog_indices_veog).union(set(eog_indices_hoeg)))



    # barplot of ICA component "EOG match" scores

    fig1=ica.plot_properties(eeg_data_interp_ref, picks=union_indices_eog)
    for x in range(len(union_indices_eog)):
        fig1[x].savefig(opj(prepro_dir, subject +'-ICA_properties_'+str(x+1)+'.png'))

     # plot ICs applied to raw data, with EOG matches highlighted
    fig=ica.plot_sources(eeg_data_interp_ref)
    fig.savefig(opj(prepro_dir, subject +'-ICA_sources.png'))

    ica.exclude = union_indices_eog

    print(ica.exclude)

    # apply ICA to unfiltered data
    ica.apply(eeg_data_interp_ref)

    print("---  ICA done ---" )

    eeg_data_interp_ref.save(opj(prepro_dir,subject+'_task_after_ica_raw_filtered.fif'), overwrite = True)
    
    
    

"""
from pyprep-final.ipynb
"""

for x in range(len(union_indices_eog)):
    fig1[x].savefig(opj(prepro_dir, subject +'-ICA_properties_'+str(x+1)+'.png'))

 # plot ICs applied to raw data, with EOG matches highlighted
fig=ica.plot_sources(eeg_data_interp_ref)
fig.savefig(opj(prepro_dir, subject +'-ICA_sources.png'))

ica.exclude = union_indices_eog

print(ica.exclude)

# apply ICA to unfiltered data
eeg_data_unfiltered_ica = prep.raw.copy()
ica.apply(eeg_data_unfiltered_ica)

print("---  ICA done ---" )

eeg_data_unfiltered_ica.save(opj(prepro_dir,subject+'_task_after_ica_raw_unfiltered.fif'), overwrite = True)
    
    
    
    
    
    
    
    
    
    
    
'''
epoching
'''

# RESAMPLE with mne.Epochs.decimate()
# https://mne.tools/stable/overview/faq.html#resampling-and-decimating
    
    
# extract current sampling rate
s_rate = raw.info["sfreq"]
    
    
    
    
    
    
    
    
    
    
    