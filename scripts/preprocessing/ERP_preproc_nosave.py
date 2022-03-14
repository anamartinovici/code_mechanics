#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
Preprocessing of raw data for ERP analysis 

@author: Antonio Schettino
'''

# %% IMPORT LIBRARIES

import random
import numpy as np
import pandas as pd
import os
import mne
import pathlib

from os.path import join as opj
from mne_bids import BIDSPath
from pyprep import NoisyChannels
from mne.preprocessing import ICA
from autoreject import AutoReject

# %% SETUP

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

# directories
raw_path = '/home/aschetti/Documents/Projects/code_mechanics/data/raw/eeg_BIDS/' # directory with raw data
preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/data/preproc/' # directory with preprocessed files
events_path = '/home/aschetti/Documents/Projects/code_mechanics/data/events/' # directory with event files

datatype = 'eeg' # data type

# define electrode montage
montage = mne.channels.make_standard_montage("biosemi64")
# montage.plot() # visualize montage

# filter cutoffs
cutoff_low = 0.1
cutoff_high = 40

# number of components for ICA decomposition
ICA_n_comps = 20

# triggers (from TriggerTable.csv)
trigs = pd.read_csv(opj(events_path, 'TriggerTable.csv'))
#     'manmade/new/hit/forgotten': 1010,
#     'manmade/new/hit/remembered': 1011,
#     'manmade/new/hit/na': 1019,
#     'manmade/new/miss/forgotten': 1020,
#     'manmade/new/miss/remembered': 1021,
#     'manmade/new/miss/na': 1029,
#     'manmade/new/fa/forgotten': 1030,
#     'manmade/new/fa/remembered': 1031,
#     'manmade/new/fa/na': 1039,             
#     'manmade/new/cr/forgotten': 1040,
#     'manmade/new/cr/remembered': 1041,
#     'manmade/new/cr/na': 1049,
#     'manmade/new/na/forgotten': 1090,
#     'manmade/new/na/remembered': 1091,
#     'manmade/new/na/na': 1099,
#     'manmade/old/hit/forgotten': 1110,
#     'manmade/old/hit/remembered': 1111,
#     'manmade/old/hit/na': 1119,
#     'manmade/old/miss/forgotten': 1120,
#     'manmade/old/miss/remembered': 1121,
#     'manmade/old/miss/na': 1129,
#     'manmade/old/na/forgotten': 1190,
#     'manmade/old/na/remembered': 1191,
#     'manmade/old/na/na': 1199,
#     'natural/new/hit/forgotten': 2010,
#     'natural/new/hit/remembered': 2011,
#     'natural/new/hit/na': 2019,
#     'natural/new/miss/forgotten': 2020,
#     'natural/new/miss/remembered': 2021,
#     'natural/new/miss/na': 2029,
#     'natural/new/fa/forgotten': 2030,
#     'natural/new/fa/remembered': 2031,
#     'natural/new/fa/na': 2039,
#     'natural/new/cr/forgotten': 2040,
#     'natural/new/cr/remembered': 2041,
#     'natural/new/cr/na': 2049,
#     'natural/new/na/forgotten': 2090,
#     'natural/new/na/remembered': 2091,
#     'natural/new/na/na': 2099,
#     'natural/old/hit/forgotten': 2110,
#     'natural/old/hit/remembered': 2111,
#     'natural/old/hit/na': 2119,
#     'natural/old/miss/forgotten': 2120,
#     'natural/old/miss/remembered': 2121,
#     'natural/old/miss/na': 2129,
#     'natural/old/na/forgotten': 2190,
#     'natural/old/na/remembered': 2191,
#     'natural/old/na/na': 2199

# combined triggers according to research questions
# Q1
# 'manmade' condition
# NOTE: 'manmade' excludes NAs in behavior: 
# although scene category is independent from response, 
# NAs may reflect drops in attention and, consequently, incomplete stimulus perception
trigs_Q1_manmade = trigs[(trigs['scene_category'] == 'man-made') 
                         & (trigs['behavior'] != 'na')
                         ]['trigger']
# 'natural' condition
# NOTE: 'natural' excludes NAs in behavior: 
# although scene category is independent from response, 
# NAs may reflect drops in attention and, consequently, incomplete stimulus perception
trigs_Q1_natural = trigs[(trigs['scene_category'] == 'natural') 
                         & (trigs['behavior'] != 'na')
                         ]['trigger']
# Q2
# 'new' condition
# NOTE: 'new' excludes NAs in behavior (possible drops in attention) 
# but must include NAs in memory: 
# by definition, a new picture cannot be successfully or unsuccessfully recognized as old
trigs_Q2_new = trigs[(trigs['old'] == 'new') 
                         & (trigs['behavior'] != 'na')
                         ]['trigger']
# 'old' condition
# NOTE: 'old' excludes NAs in behavior (possible drops in attention) 
# but can include NAs in memory: 
# the point is whether the image has been initially categorized as old, 
# regardless of whether it's recognized as such in subsequent presentations
trigs_Q2_old = trigs[(trigs['old'] == 'old') 
                         & (trigs['behavior'] != 'na')
                         ]['trigger']
# Q3
# 'old-hit'
# NOTE: 'old-hit' must only include 
# old in presentation and hit in behavior but can include NAs in memory: 
# the point is whether the image has been initially successfully categorized as old, 
# regardless of whether it's recognized as such in subsequent presentations
trigs_Q3_old_hit = trigs[(trigs['old'] == 'old') 
                         & (trigs['behavior'] == 'hit')
                         ]['trigger']
# 'old-miss'
# NOTE: 'old-miss' must only include 
# old in presentation and misses in behavior but can include NAs in memory: 
# the point is whether the image has been initially unsuccessfully categorized as old, 
# regardless of whether it's recognized as such in subsequent presentations
trigs_Q3_old_miss = trigs[(trigs['old'] == 'old') 
                         & (trigs['behavior'] == 'miss/forgotten')
                         ]['trigger']
# Q4
# 'remembered'
# NOTE: 'remembered' can be both 'new' and 'old', 
# because by definition 'new' pictures shown only once cannot be subsequently remembered/forgotten
# can include hits and misses and NAs 
# and must not include NAs in memory
trigs_Q4_remembered = trigs[trigs['subsequent_correct'] == 'subsequent_remembered'
                            ]['trigger']
# 'forgotten'
# NOTE: 'forgotten' can be both 'new' and 'old', 
# because by definition 'new' pictures shown only once cannot be subsequently remembered/forgotten
# can include hits and misses and NAs 
# and must not include NAs in memory
trigs_Q4_forgotten = trigs[trigs['subsequent_correct'] == 'subsequent_forgotten'
                         ]['trigger']

# epoch length (relative to stimulus)
begin_epoch = -0.2
end_epoch = 0.5

# AutoReject parameters
ar = AutoReject(
    n_interpolate = None, # (default) values to try for the number of channels for which to interpolate (default: np.array([1, 4, 32]))
    consensus = None, # (default) values to try for percentage of channels that must agree as a fraction of the total number of channels (default: np.linspace(0, 1.0, 11))
    cv = 10, # cross-validation object
    picks = datatype,
    thresh_method = 'bayesian_optimization',
    random_state = project_seed # RNG seed
    )

# %% PREPROCESSING

# get all participant names
subs = [name for name in os.listdir(raw_path) if name.startswith('sub')] 

for ssj in subs:
    
    # create subdirectory
    pathlib.Path(opj(preproc_path + ssj)).mkdir(exist_ok = True) 
    
    # message in console
    print("--- load " + ssj + " ---")
    
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
        check = True # check BIDS conformity
        )
    
    # load data
    raw = mne.io.read_raw_brainvision(
        bids_path, 
        eog = ('VEOG', 'HEOG','IO1','IO2','Afp9','Afp10'), # ocular channels
        misc = ('M1','M2'), # mastoid channels
        preload = True
        )        
    
    # # plot raw data
    # raw.plot(
    #     duration = 20, # time window (in seconds)
    #     start = 20, # start time (in seconds)
    #     n_channels = len(raw.ch_names), # number of channels to plot
    #     color = 'darkblue', # line color
    #     bad_color = 'red', # line color: bad channels
    #     remove_dc = True, # remove DC component (visualization only)
    #     proj = False, # apply projectors prior to plotting
    #     group_by = 'type', # group by channel type
    #     butterfly = False # butterfly mode        
    #     )
    
    # check data info    
    print(raw.info)
    
    # %% ELECTRODE MONTAGE

    # message in console
    print("--- assign electrode montage ---")
    
    # assign electrode montage
    raw = raw.set_montage(montage)
    
    # %% FILTERING
    
    # message in console
    print("--- high-pass and low-pass filters ---")
    
    # filter data
    raw = raw.filter( # apply high-pass filter
        l_freq = cutoff_low,
        h_freq = None).filter( # apply low-pass filter
            l_freq = None,
            h_freq = cutoff_high
            )

    # # plot filtered data
    # raw.plot(
    #     duration = 20,
    #     start = 20,
    #     n_channels = len(raw.ch_names),
    #     color = 'darkblue',
    #     bad_color = 'red',
    #     remove_dc = True,
    #     proj = False,
    #     group_by = 'type',
    #     butterfly = False     
    #     )

    # %% BAD CHANNEL DETECTION

    # message in console
    print("--- detect noisy channels ---")

    # detect noisy channels
    nd = NoisyChannels(
        raw,
        # do not apply 1 Hz high-pass filter before bad channel detection:
        # the data have already been high-pass filtered at 0.1 Hz
        # and we don't want to miss bad channels with slow drifts
        do_detrend = False,
        random_state = project_seed # RNG seed
        )
    
    # detect noisy channels based on:
    # - missing signal (NaN)
    # - flat signal
    # - deviation
    # - HF noise (frequency components > 50 Hz considerably higher than median channel noisiness)
    # - correlation
    #   - bad correlation window if maximum correlation with another channel is below the provided correlation threshold (default: 0.4)
    #   - a channel is “bad-by-correlation” if its fraction of bad correlation windows is above the bad fraction threshold (default: 0.01)
    # - low signal-to-noise ratio (too much high-frequency noise + low channel correlation)
    # - dropout (long time windows with completely flat signal, default fraction threshold 0.01)
    # - RANSAC (random sample consensus approach): predict signal based on signals and spatial locations of other currently-good channels
    #   - split recording into non-overlapping time windows (default: 5 seconds)
    #   - correlate each channel’s RANSAC-predicted signal with its actual signal
    #   - bad window if predicted vs. actual signal correlation below correlation threshold (default: 0.75)
    #   - bad channel if its fraction of bad RANSAC windows is above threshold (default: 0.4)
    # for more info, see https://pyprep.readthedocs.io/en/latest/generated/pyprep.NoisyChannels.html#pyprep.NoisyChannels
    nd.find_all_bads(
        ransac = True, 
        channel_wise = False
        )
    
    # extract bad channels
    bads = nd.get_bads(verbose = True)
       
    # add bad channel info to filtered data 
    raw.info['bads'] = bads 
        
    # # plot filtered data with bad channels in red
    # raw.plot(
    #     duration = 20,
    #     start = 20,
    #     n_channels = len(raw.ch_names),
    #     color = 'darkblue',
    #     bad_color = 'red',
    #     remove_dc = True,
    #     proj = False,
    #     group_by = 'type',
    #     butterfly = False     
    #     )
    
    # save bad channels to file
    with open(opj(preproc_path + ssj, ssj + '_bad_channels.txt'), 'w') as f:
        for item in bads:
            f.write("%s\n" % item)
    
    # %% CHANNEL INTERPOLATION
    
    # message in console
    print("--- interpolate noisy channels ---")
    
    # interpolate bad channels (spherical spline interpolation)    
    raw = raw.interpolate_bads(
        reset_bads = True # remove bad channel list from info
        )        
        
    # # plot filtered data with interpolated channels
    # raw.plot(
    #     duration = 20,
    #     start = 20,
    #     n_channels = len(raw.ch_names),
    #     color = 'darkblue',
    #     bad_color = 'red', # in case some bad channels are still in the data
    #     remove_dc = True,
    #     proj = False,
    #     group_by = 'type',
    #     butterfly = False
    #     )
    
    # %% REFERENCING
    
    # message in console
    print("--- referencing ---")
     
    # average reference
    raw = raw.set_eeg_reference(ref_channels = 'average') 

    # %% SAVE DATA
    
    # raw.save(opj(preproc_path + ssj, ssj + '_eeg.fif'), overwrite = True)
    
    # %% ARTIFACT CORRECTION: ICA
    # https://mne.tools/stable/auto_tutorials/preprocessing/40_artifact_correction_ica.html?highlight=ica
    
    # # load data (for debugging only)
    # raw = mne.io.read_raw_fif(
    #     opj(preproc_path + ssj, ssj + '_eeg.fif'),
    #     preload = True
    #     )

    # message in console
    print("--- start ICA ---" )

    # apply 1 Hz high-pass filter before ICA
    raw_ICA = raw.filter(l_freq = 1, h_freq = None)

    # ICA parameters
    ica = ICA(
        n_components = ICA_n_comps,
        noise_cov = None, # channels are scaled to unit variance (“z-standardized”) prior to whitening by PCA
        # 'picard': algorithm that converges faster than 'fastica' and 'infomax' 
        # and is more robust when sources are not completely independent (typical for EEG signal)
        method = 'picard',
        fit_params = None, # use defaults of selected ICA method              
        max_iter = 'auto',  # max number of iterations
        random_state = project_seed # RNG seed
        )

    # fit ICA to low-pass filtered data
    ica.fit(raw_ICA)
    
    # find components that match the vertical EOG pattern
    eog_indices_veog, eog_scores_veog = ica.find_bads_eog(raw, ch_name = 'VEOG')
    
    # find components that match the horizontal EOG pattern
    eog_indices_hoeg, eog_scores_heog = ica.find_bads_eog(raw, ch_name = 'HEOG')

    # merge vEOG and hEOG components
    union_indices_eog = list(set(eog_indices_veog).union(set(eog_indices_hoeg)))
    
    # assign artifactual ICA components to exclude from data
    ica.exclude = union_indices_eog

    # apply ICA to unfiltered data
    raw = ica.apply(raw)
    
    # # plot clean data
    # raw.plot(
    #     duration = 20,
    #     start = 20,
    #     n_channels = len(raw.ch_names),
    #     color = 'darkblue',
    #     bad_color = 'red',
    #     remove_dc = True,
    #     proj = False,
    #     group_by = 'type',
    #     butterfly = False
    #     )
    
    # plot components (topographies)    
    ica.plot_components()

    # message in console
    print("--- end ICA ---" )

    # %% SAVE DATA
    
    # raw.save(opj(preproc_path + ssj, ssj + '_eeg.fif'), overwrite = True)
    
    # %% CREATE EPOCHS (ALL CONDITIONS)

    # # load data (for debugging only)
    # raw = mne.io.read_raw_fif(
    #     opj(preproc_path + ssj, ssj + '_eeg.fif'),
    #     preload = True
    #     )

    # message in console
    print("--- create epochs ---")

    # load event file
    events_csv = pd.read_csv(opj(events_path, 'EMP' + ssj[-2:] + '_events.csv'))    
    events = events_csv[['latency','trial','trigger']].to_numpy(dtype = int)

    # visualize events
    mne.viz.plot_events(
        events,
        sfreq = raw.info['sfreq'] # sample frequency (to display data in seconds)
        )
    
    # create epochs (all conditions)
    # NOTE: epochs are subsampled (512 Hz --> 128 Hz),
    # to lower the chances of Type II error in subsequent statistical analyses
    epochs = mne.Epochs(
        raw, 
        events, # events
        tmin = begin_epoch, # start epoch
        tmax = end_epoch, #end epoch
        baseline = (begin_epoch, 0), # time window for baseline correction
        picks = None, # include all channels 
        preload = True,
        decim = 4, # subsample data by a factor of 4, i.e., 128 Hz (for more info, see https://mne.tools/stable/overview/faq.html#resampling-and-decimating)
        detrend = None, # do not detrend before baseline correction        
        reject_by_annotation = False # do not reject based on annotations
        )
    
    # # plot epochs
    # epochs.plot(
    #     picks = datatype,
    #     scalings = None,
    #     n_epochs = 5, 
    #     n_channels = 64, 
    #     events = events,
    #     butterfly = False
    #     )

    # %% ARTIFACT REJECTION
    # artifact rejection is run on all conditions simultanously, 
    # to avoid bias due to condition-specific artifacts
      
    # message in console
    print("--- run AutoReject ---")
    
    # run artifact rejection
    ar.fit(epochs)  # fit on all epochs
    epochs_clean, reject_log = ar.transform(epochs, return_log = True) 
    
    # visualize reject log
    reject_log.plot('horizontal')
    
    # list rejected epochs
    dropped_epochs = list(np.where(reject_log.bad_epochs)[0])
    
    with open(opj(preproc_path + ssj, ssj + '_droppedEpochs.txt'), 'w') as file:
        for x in dropped_epochs:
            file.write("%i\n" % x)
    
    # %% SAVE DATA
    
    epochs_clean.save(opj(preproc_path + ssj, ssj + '_AutoReject_epo.fif'), overwrite = True)
    
    # %% CREATE EPOCHS
    # create epochs for different research questions
    
    # # load data (for debugging only)
    # epochs_clean = mne.read_epochs(
    #     opj(preproc_path, ssj + '_epochs_AutoReject.fif'),
    #     preload = True
    #     )    
    
    # message in console
    print("--- create condition-specific epochs ---")
    
    # create epochs
    # convert to string each trigger in the list,
    # create epochs, and save them to file
    epochs_manmade = epochs_clean[[str(i) for i in trigs_Q1_manmade]].save(opj(preproc_path + ssj, ssj + '_manmade_epo.fif'), overwrite = True) # 'manmade'
    epochs_natural = epochs_clean[[str(i) for i in trigs_Q1_natural]].save(opj(preproc_path + ssj, ssj + '_natural_epo.fif'), overwrite = True) # 'natural'
    epochs_new = epochs_clean[[str(i) for i in trigs_Q2_new]].save(opj(preproc_path + ssj, ssj + '_new_epo.fif'), overwrite = True) # 'new'
    epochs_old = epochs_clean[[str(i) for i in trigs_Q2_old]].save(opj(preproc_path + ssj, ssj + '_old_epo.fif'), overwrite = True) # 'old'
    epochs_old_hit = epochs_clean[[str(i) for i in trigs_Q3_old_hit]].save(opj(preproc_path + ssj, ssj + '_old_hit_epo.fif'), overwrite = True) # 'old-hit'
    epochs_old_miss = epochs_clean[[str(i) for i in trigs_Q3_old_miss]].save(opj(preproc_path + ssj, ssj + '_old_miss_epo.fif'), overwrite = True) # 'old-miss'
    epochs_remembered = epochs_clean[[str(i) for i in trigs_Q4_remembered]].save(opj(preproc_path + ssj, ssj + '_remembered_epo.fif'), overwrite = True) # 'remembered'
    epochs_forgotten = epochs_clean[[str(i) for i in trigs_Q4_forgotten]].save(opj(preproc_path + ssj, ssj + '_forgotten_epo.fif'), overwrite = True) # 'forgotten'

    # %% END
    
    # message in console
    print("--- end ---")
    