#!/bin/bash

# options are: 'personal', 'RSM_laptop', and 'RSM_PC'
machine_name='personal' 

copy_from_dir_personal='/c/Users/anama/Dropbox/Research/Data/EEG_Many_Pipelines/code_mechanics'
copy_to_dir_personal='/c/Users/anama/OneDrive/Desktop/to_be_submitted'
project_dir_personal='/c/Users/anama/OneDrive/Desktop/code_mechanics'

aux="copy_from_dir_${machine_name}"
copy_from_dir=${!aux}
aux="copy_to_dir_${machine_name}"
copy_to_dir=${!aux}
aux="project_dir_${machine_name}"
project_dir=${!aux}

# start from a clean slate
rm -rf "${copy_to_dir}/Data"
mkdir -p "${copy_to_dir}/Data"

declare -a participants=('01' '02' '03' '04' '05' '06' '07' '08' '09' '10' \
                         '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' \
                         '21' '22' '23' '24' '25' '26' '27' '28' '29' '30' \
                         '31' '32' '33')

# prepare the structure of each participant folder
for partID in ${participants[@]}
do
	mkdir -p "${copy_to_dir}/Data/Subj${partID}/Pre-processed time series data/ERP"
	mkdir -p "${copy_to_dir}/Data/Subj${partID}/Removed ICA components (txt files)/ERP"
	mkdir -p "${copy_to_dir}/Data/Subj${partID}/Excluded trials (txt files)/ERP"
	mkdir -p "${copy_to_dir}/Data/Subj${partID}/Excluded sensors (txt files)/ERP"
	
	mkdir -p "${copy_to_dir}/Data/Subj${partID}/Pre-processed time series data/TFR"
	mkdir -p "${copy_to_dir}/Data/Subj${partID}/Removed ICA components (txt files)/TFR"
	mkdir -p "${copy_to_dir}/Data/Subj${partID}/Excluded trials (txt files)/TFR"
	mkdir -p "${copy_to_dir}/Data/Subj${partID}/Excluded sensors (txt files)/TFR"
done


copy_from="${copy_from_dir}/data_outside_repo/processed_data"
for partID in ${participants[@]}
do
	copy_to="${copy_to_dir}/Data/Subj${partID}"

	# Pre-processed time series data
	# ERP
	cp "${copy_from}/ERP/step1/sub-0${partID}/sub-0${partID}_AutoReject_epo.fif" \
	   "${copy_to}/Pre-processed time series data/ERP"
	# TFR
	cp "${copy_from}/TFR/step1/sub-0${partID}/sub-0${partID}_AutoReject_epo.fif" \
	   "${copy_to}/Pre-processed time series data/TFR"

	# Removed ICA components (txt files)


    # Excluded trials (txt files)
    # ERP
    cp "${copy_from}/ERP/step1/sub-0${partID}/sub-0${partID}_droppedEpochs.txt" \
       "${copy_to}/Excluded trials (txt files)/ERP"
    # TFR
    cp "${copy_from}/TFR/step1/sub-0${partID}/sub-0${partID}_droppedEpochs.txt" \
       "${copy_to}/Excluded trials (txt files)/TFR"
    
    # Excluded sensors (txt files)
    # ERP
    cp "${copy_from}/ERP/step1/sub-0${partID}/sub-0${partID}_bad_channels.txt" \
       "${copy_to}/Excluded sensors (txt files)/ERP"
    # TFR
    cp "${copy_from}/TFR/step1/sub-0${partID}/sub-0${partID}_bad_channels.txt" \
       "${copy_to}/Excluded sensors (txt files)/TFR"
done


