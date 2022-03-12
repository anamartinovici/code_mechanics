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
# import glob
# import re
# import matplotlib.pyplot as plt
import os
import mne
# import time

from os.path import join as opj
from mne_bids import BIDSPath
from pyprep import NoisyChannels
from mne.preprocessing import ICA
# from mne_bids import BIDSPath, read_raw_bids, print_dir_tree, make_report
# from mne.preprocessing import ICA, create_eog_epochs, create_ecg_epochs, corrmap
# from autoreject import AutoReject

# %% SETUP

project_seed = 999 # RNG seed
random.seed(project_seed) # set seed to ensure computational reproducibility

# directories
raw_path = '/home/aschetti/Documents/Projects/code_mechanics/data/raw/eeg_BIDS/' # directory with raw data
preproc_path = '/home/aschetti/Documents/Projects/code_mechanics/data/preproc/' # directory with preprocessed files
events_path = '/home/aschetti/Documents/Projects/code_mechanics/data/events/' # directory with event files

# filenames = glob.glob(preproc_path + '/*.fif') # list of .fif files in directory

# conditions = ['manmade', 'natural'] # condition names

datatype = 'eeg'

# sub_pattern = re.compile(r"\bsub-0\w*-\b") # regex pattern for plot titles 

# define electrode montage
montage = mne.channels.make_standard_montage("biosemi64")
# montage.plot() # visualize montage

# filter cutoffs
cutoff_low = 0.1
cutoff_high = 40

# referencing method
ref_method = 'average' # it could also be 'mastoid', but I prefer average reference

# number of components for ICA decomposition
ICA_n_comps = 20

# triggers (from TriggerTable.csv)
triggers_dict = {'man-made/new/hit/forgotten': 1010,
                 'man-made/new/hit/remembered': 1011,
                 'man-made/new/hit/na': 1019,
                 'man-made/new/miss/forgotten': 1020, 
                 'man-made/new/miss/remembered': 1021,
                 'man-made/new/miss/na': 1029,
                 'man-made/new/fa/forgotten': 1030,
                 'man-made/new/fa/remembered': 1031,
                 'man-made/new/fa/na': 1039,                  
                 'man-made/new/cr/forgotten': 1040,
                 'man-made/new/cr/remembered': 1041,
                 'man-made/new/cr/na': 1049,
                 'man-made/new/na/forgotten': 1090,
                 'man-made/new/na/remembered': 1091,
                 'man-made/new/na/na': 1099,
                 'man-made/old/hit/forgotten': 1110,
                 'man-made/old/hit/remembered': 1111,
                 'man-made/old/hit/na': 1119, 
                 'man-made/old/	miss/forgotten': 1120,
                 'man-made/old/	miss/remembered': 1121,
                 'man-made/old/	miss/na': 1129,  
                 'man-made/old/	na/forgotten': 1190,
                 'man-made/old/	na/remembered': 1191,
                 'man-made/old/	na/na': 1199,  
                 'natural/new/hit/forgotten': 2010, 
                 'natural/new/hit/remembered': 2011,
                 'natural/new/hit/na': 2019,
                 'natural/new/miss/forgotten': 2020,    
                 'natural/new/miss/remembered': 2021,
                 'natural/new/miss/na': 2029,
                 'natural/new/fa/forgotten': 2030,
                 'natural/new/fa/remembered': 2031,
                 'natural/new/fa/na': 2039,      
                 'natural/new/cr/forgotten': 2040,   
                 'natural/new/cr/remembered': 2041,
                 'natural/new/cr/na': 2049,  
                 'natural/new/na/forgotten': 2090, 
                 'natural/new/na/remembered': 2091,  
                 'natural/new/na/na': 2099,        
                 'natural/old/hit/forgotten': 2110,
                 'natural/old/hit/remembered': 2111,
                 'natural/old/hit/na': 2119,        
                 'natural/old/miss/forgotten': 2120,
                 'natural/old/miss/remembered': 2121,
                 'natural/old/miss/na': 2129,     
                 'natural/old/na/forgotten': 2190,
                 'natural/old/na/remembered': 2191,
                 'natural/old/na/na': 2199}

# get all subject numbers
subs = [ name for name in os.listdir(raw_path) if name.startswith('sub') ] 

# %% PREPROCESSING

for ssj in subs[:1]:
    
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
    
    # check data info    
    print(raw.info)
    
    # %% ELECTRODE MONTAGE

    # message in console
    print("--- assign electrode montage ---")
    
    # assign electrode montage
    raw = raw.set_montage(montage)
        
    # # create backup copy of raw data
    # raw_backup = raw.copy()    
    
    # %% FILTERING
    
    # message in console
    print("--- high-pass and low-pass filters ---")
    
    # filter data
    raw_filt = raw.filter( # apply high-pass filter
        l_freq = cutoff_low,
        h_freq = None).filter( # apply low-pass filter
            l_freq = None,
            h_freq = cutoff_high
            )

    # plot filtered data
    raw_filt.plot(
        duration = 20, # time window (in seconds)
        start = 20, # start time (in seconds)
        n_channels = len(raw_filt.ch_names), # number of channels to plot
        color = 'darkblue', # line color
        bad_color = 'red', # line color: bad channels
        remove_dc = True, # remove DC component (visualization only)
        proj = False, # apply projectors prior to plotting
        group_by = 'type', # group by channel type
        butterfly = False # butterfly mode        
        )

    # # create backup copy of filtered data
    # raw_filt_backup = raw_filt.copy()   

    # %% BAD CHANNEL DETECTION

    # message in console
    print("--- detect noisy channels ---")

    # detect noisy channels
    nd = NoisyChannels(
        raw_filt,
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
    # - HF noise (frequency components > 50 Hz considerably higher than median channel noisiness )
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
    raw_filt.info['bads'] = bads 
        
    # plot filtered data with bad channels in red
    raw_filt.plot(
        duration = 20, # time window (in seconds)
        start = 20, # start time (in seconds)
        n_channels = len(raw_filt.ch_names), # number of channels to plot
        color = 'darkblue', # line color
        bad_color = 'red', # line color: bad channels
        remove_dc = True, # remove DC component (visualization only)
        proj = False, # apply projectors prior to plotting
        group_by = 'type', # group by channel type
        butterfly = False # butterfly mode        
        )
    
    # save bad channels to file
    with open(opj(preproc_path, ssj + '_bad_channels.txt'), 'w') as f:
        for item in bads:
            f.write("%s\n" % item)
    
    # %% CHANNEL INTERPOLATION
    
    # message in console
    print("--- interpolate noisy channels ---")
    
    # interpolate bad channels (spherical spline interpolation)    
    raw_filt_interp = raw_filt.interpolate_bads(
        reset_bads = True # remove bad channel list from info
        )        
        
    # plot filtered data with interpolated channels
    raw_filt_interp.plot(
        duration = 20, # time window (in seconds)
        start = 20, # start time (in seconds)
        n_channels = len(raw_filt_interp.ch_names), # number of channels to plot
        color = 'darkblue', # line color
        bad_color = 'red', # line color: bad channels
        remove_dc = True, # remove DC component (visualization only)
        proj = False, # apply projectors prior to plotting
        group_by = 'type', # group by channel type
        butterfly = False # butterfly mode        
        )
    
    # # create backup copy of interpolated data
    # raw_filt_interp_backup = raw_filt_interp.copy()  
    
    # %% REFERENCING
    
    # message in console
    print("--- referencing ---")
    
    # referencing
    if ref_method == 'average':
        raw_filt_interp_ref = raw_filt_interp.set_eeg_reference(ref_channels = 'average')
    elif ref_method=='mastoid':
        raw_filt_interp_ref = raw_filt_interp.set_eeg_reference(ref_channels = ['M1', 'M2'])

    # # create backup copy of referenced data
    # raw_filt_interp_ref_backup = raw_filt_interp_ref.copy()  

    # %% SAVE DATA
    
    raw_filt_interp_ref.save(opj(preproc_path, ssj + '_filt_interp_ref.fif'), overwrite = True)
    
    # %% ARTIFACT REJECTION: ICA
    # https://mne.tools/stable/auto_tutorials/preprocessing/40_artifact_correction_ica.html?highlight=ica
    
    # # load data (for debugging only)
    # raw_filt_interp_ref = mne.io.read_raw_fif(
    #     opj(preproc_path, ssj + '_filt_interp_ref.fif'),
    #     preload = True
    #     )

    # message in console
    print("--- start ICA ---" )

    # apply 1 Hz high-pass filter before ICA
    raw_ICA_filt = raw_filt_interp_ref.filter(l_freq = 1, h_freq = None)

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
    ica.fit(raw_ICA_filt)
    
    # find components that match the vertical EOG pattern
    eog_indices_veog, eog_scores_veog = ica.find_bads_eog(raw_filt_interp_ref, ch_name = 'VEOG')
    
    # find components that match the horizontal EOG pattern
    eog_indices_hoeg, eog_scores_heog = ica.find_bads_eog(raw_filt_interp_ref, ch_name = 'HEOG')

    # merge vEOG and hEOG components
    union_indices_eog = list(set(eog_indices_veog).union(set(eog_indices_hoeg)))
    
    # assign artifactual ICA components to exclude from data
    ica.exclude = union_indices_eog

    # apply ICA to unfiltered data
    raw_filt_interp_ref_ICA = ica.apply(raw_filt_interp_ref)
    
    # plot clean data
    raw_filt_interp_ref_ICA.plot(
        duration = 20, # time window (in seconds)
        start = 20, # start time (in seconds)
        n_channels = len(raw_filt_interp_ref_ICA.ch_names), # number of channels to plot
        color = 'darkblue', # line color
        bad_color = 'red', # line color: bad channels
        remove_dc = True, # remove DC component (visualization only)
        proj = False, # apply projectors prior to plotting
        group_by = 'type', # group by channel type
        butterfly = False # butterfly mode        
        )
    
    # plot components (topographies)    
    ica.plot_components()

    # message in console
    print("--- end ICA ---" )

    # %% SAVE DATA
    raw_filt_interp_ref_ICA.save(opj(preproc_path, ssj + '_filt_interp_ref_ICA.fif'), overwrite = True)
    
    # %% EPOCHING
    # https://mne.tools/stable/overview/faq.html#resampling-and-decimating

    # load data (for debugging only)
    raw_filt_interp_ref_ICA = mne.io.read_raw_fif(
        opj(preproc_path, ssj + '_filt_interp_ref_ICA.fif'),
        preload = True
        )

    # read event file
    events_csv = pd.read_csv(opj(events_path, 'EMP' + ssj[-2:] + '_events.csv'))
    events = events_csv[['latency','trial','trigger']].to_numpy(dtype = int)










    # 
    events_manmade = mne.merge_events(events, range(1000, 1999), 1000, replace_events = True)
    events_natural = mne.merge_events(new_events, range(2000, 2999), 2000, replace_events = True)





    events = mne.find_events(
        raw_filt_interp_ref_ICA, 
        stim_channel=None, 
        output='onset', 
        consecutive='increasing', 
        min_duration=0, 
        shortest_event=2, 
        mask=None,
        uint_cast=False, 
        mask_type='and', 
        initial_event=False,
        verbose=None
        )
    
    

    # resample
    # for more info, see https://mne.tools/stable/overview/faq.html#resampling-and-decimating

    
    
    # %% ARTIFACT REJECTION: AUTOREJECT
    # https://autoreject.github.io/stable/auto_examples/plot_autoreject_workflow.html#plot-autoreject-workflow
    
    
    
    
    # starting from a relative path /eeg_BIDS which you should also have
bids_root = '../eeg_BIDS/'

subs = [ name for name in os.listdir(bids_root) if name.startswith('sub') ]

n_jobs = 10

for subject in subs:
    
    print(subject)

    prepro_dir = opj(bids_root,'Preprocessed',subject)
    prepro_data = mne.io.read_raw_fif(glob(opj(prepro_dir, '*unf*'))[0], preload=True)



    # # Filtering is needed before artefact rejection see: https://autoreject.github.io/stable/auto_examples/plot_autoreject_workflow.html#plot-autoreject-workflow
    # cutoff_l = 0.1
    # prepro_data_highpass = prepro_data.copy().filter(l_freq=cutoff_l, h_freq=None)

    # events_dir = '/data04/Sebastian/EMP/events/'

    # events_csv = pd.read_csv(glob(opj(events_dir,'EMP'+subject[-2:]+'*.csv'))[0])
    # events = events_csv[['latency','trial','trigger']].to_numpy(dtype = int)

    new_events=mne.merge_events(events,range(1000,1999),1000, replace_events=True)
    new_events=mne.merge_events(new_events,range(2000,2999),2000, replace_events=True)

    #---------- Epoching and Artefact Rejection -------------#

    events_of_interest = {
        'manmade': 1000,
        'natural': 2000}

    # epoching the data to -200ms before stimulus onset to 500 ms after stimulus onset when the pictures disappears
    epoched_data = mne.Epochs(prepro_data_highpass, new_events, tmin=-0.2, tmax=0.5,baseline=None,
                        event_id =events_of_interest,
                        reject_by_annotation=False, preload=True)

    epoch_dir = opj(bids_root,'Epoched')
    ensure_dir(epoch_dir)
    epoched_data.save(opj(epoch_dir,subject+'-epo-ERP_RQ1_'+str(cutoff_l)+'_HP_.fif'), overwrite=True)


    ar = AutoReject(verbose='tqdm_notebook', n_jobs=n_jobs, random_state=234)
    epoched_data_clean_ar, rejection_log_fix = ar.fit_transform(epoched_data, return_log=True)

    autoreject_dir = opj(bids_root,'AutoReject')
    ensure_dir(autoreject_dir)
    epoched_data_clean_ar.save(opj(autoreject_dir,subject+'-epo-ERP_RQ1_autoreject_'+str(cutoff_l)+'_HP_.fif'), overwrite = True)
    # extract the indices of the dropped epochs and save them to a txt file

    dropped_epochs = list(np.where(rejection_log_fix.bad_epochs)[0])

    with open(opj(autoreject_dir,subject+'_droppedEpochs.txt'), 'w') as file:
        for x in dropped_epochs:
            file.write("%i\n" % x)
    
    
    
    
    
    
    
    
    print(events[:5])  # show the first 5



    epochs_RQ1 = mne.Epochs(
        raw_filt_interp_ref_ICA,
        events, 
        event_id=None, 
        tmin=- 0.2,
        tmax=0.5,
        baseline=(None, 0),
        picks=None, 
        preload=False, 
        reject=None, 
        flat=None, 
        proj=True, 
        decim=1, 
        reject_tmin=None, 
        reject_tmax=None,
        detrend=None,
        on_missing='raise',
        reject_by_annotation=True, 
        metadata=None, 
        event_repeated='error', 
        verbose=None
        )



# RESAMPLE with mne.Epochs.decimate()
# https://mne.tools/stable/overview/faq.html#resampling-and-decimating
    
    
# extract current sampling rate
s_rate = raw.info["sfreq"]












    # %% END

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    