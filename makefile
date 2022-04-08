# for now, all has only test_make, to avoid everything building built by accident
# to build the analysis, you need to write 'make name_of_target' explicitly in the terminal
all: restore_file_timestamps RQ1 RQ2 RQ3 RQ4

#################################################
##
## set folders and other user specific info
##
#################################################

DIR_RECEIPT = zzz_receipts
# RNG seed
PROJECT_SEED = 999

# to process data, we need eeg_BIDS
# the eeg_BIDS data we received for this project is too large for GitHub
# this means we need to tell the scripts where to find these files outside of the repo

# you can choose to keep files that are too big for GitHub in a folder called `local_files`
# the folder is ignored (see .gitignore), which means that changes are not tracked

# I STRONGLY!!!! advise you to keep this folder outside of the repository
# otherwise you need to copy paste the folder every time you get a fresh clone
# and there's a high risk you will lose data 
DIR_local_files = "Specify a PATH to your local_files directory"
# the default value is set as such in order to force you to specify a path

user_name=$(shell whoami)
# this is Ana's personal laptop
ifeq "$(strip $(user_name))" "anama"
	DIR_local_files = C:/Users/anama/Dropbox/Research/Data/EEG_Many_Pipelines/local_files
endif

# this is Ana's RSM laptop
ifeq "$(strip $(user_name))" "marti"
	DIR_local_files = C:/Users/marti/Dropbox/Research/Data/EEG_Many_Pipelines/local_files
endif

# this is Ana's RSM PC
ifeq "$(strip $(user_name))" "STAFF+67003ama"
	DIR_local_files = D:/Dropbox/Research/Data/EEG_Many_Pipelines/local_files
endif

restore_file_timestamps:
	@echo "restoring commit timestamps such that Make does not build based on git clone time"
	bash scripts/restore_file_timestamps.sh
	date > $@

test_make: create_receipt_directory
	@echo "Check if success_test_make.txt is created in DIR_RECEIPT"
	$(file > $(strip $(DIR_RECEIPT))/success_test_make.txt, 'make works just fine')
	@echo "Check if saved_from_test_make_py.txt is created in DIR_RECEIPT"
	python scripts/test_make.py $(strip $(DIR_RECEIPT))

create_receipt_directory:
	mkdir -p $(strip $(DIR_RECEIPT))

#################################################
##
## from here on we have the analysis
##
#################################################

#################################################
##
## time-frequency analysis
##
#################################################

$(strip $(DIR_RECEIPT))/RQ3_TFR_analysis_NOTeq: $(strip $(DIR_RECEIPT))/RQ3_TFR_decomp_eq \
										 scripts/RQ3/TFR/TFR_RQ3b_Analysis_not_equalized_events.py
	$(print-target-and-prereq-info)
	python scripts/RQ3/TFR/TFR_RQ3b_Analysis_not_equalized_events.py \
		   $(strip $(DIR_local_files))/data_outside_repo/original_data/eeg_BIDS/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/ \
		   results_in_repo/RQ3/TFR/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ3_TFR_decomp_NOTeq: $(strip $(DIR_RECEIPT))/TFR_process_data_step2 \
										 scripts/RQ3/TFR/TFR_RQ3b_Decomposition_not_equalized_events.py
	$(print-target-and-prereq-info)
	mkdir -p results_in_repo/RQ3/TFR/not_equalized
	python scripts/RQ3/TFR/TFR_RQ3b_Decomposition_not_equalized_events.py \
		   $(strip $(DIR_local_files))/data_outside_repo/original_data/eeg_BIDS/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/ \
		   results_in_repo/RQ3/TFR/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ3_TFR_analysis_eq: $(strip $(DIR_RECEIPT))/RQ3_TFR_decomp_eq \
										 scripts/RQ3/TFR/TFR_RQ3b_Analysis_equalized_events.py
	$(print-target-and-prereq-info)
	python scripts/RQ3/TFR/TFR_RQ3b_Analysis_equalized_events.py \
		   $(strip $(DIR_local_files))/data_outside_repo/original_data/eeg_BIDS/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/ \
		   results_in_repo/RQ3/TFR/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ3_TFR_decomp_eq: $(strip $(DIR_RECEIPT))/TFR_process_data_step2 \
										 scripts/RQ3/TFR/TFR_RQ3b_Decomposition_equalized_events.py
	$(print-target-and-prereq-info)
	mkdir -p results_in_repo/RQ3/TFR/equalized
	python scripts/RQ3/TFR/TFR_RQ3b_Decomposition_equalized_events.py \
		   $(strip $(DIR_local_files))/data_outside_repo/original_data/eeg_BIDS/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/ \
		   results_in_repo/RQ3/TFR/
	date > $@
	@echo "done with $@"
	@echo "---------"


RQ2: $(strip $(DIR_RECEIPT))/RQ2_TFR_results

$(strip $(DIR_RECEIPT))/RQ2_TFR_results: $(strip $(DIR_RECEIPT))/TFR_process_data_step2 \
										 scripts/RQ2/TFR/TFR_RQ2.py
	$(print-target-and-prereq-info)
	mkdir -p results_in_repo/RQ2/TFR/
	python scripts/RQ2/TFR/TFR_RQ2.py \
		   $(strip $(DIR_local_files))/data_outside_repo/original_data/eeg_BIDS/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step2/ \
		   results_in_repo/RQ2/TFR/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/TFR_process_data_step2: $(strip $(DIR_RECEIPT))/TFR_process_data_step1 \
										        scripts/TFR_preproc_step2.py
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step2/
	python scripts/TFR_preproc_step2.py \
		   $(strip $(DIR_local_files))/data_outside_repo/original_data/eeg_BIDS/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step2/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/TFR_process_data_step1: scripts/TFR_preproc_step1.py
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/
	python scripts/TFR_preproc_step1.py \
		   $(strip $(DIR_local_files))/data_outside_repo/original_data/eeg_BIDS/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/
	date > $@
	@echo "done with $@"
	@echo "---------"

#################################################
##
## ERP
##
#################################################

RQ4: $(strip $(DIR_RECEIPT))/RQ4_results

$(strip $(DIR_RECEIPT))/RQ4_results: $(strip $(DIR_RECEIPT))/ERP_process_data_step1 \
								  	 scripts/RQ4/ERP/RQ4_group_analysis.py
	$(print-target-and-prereq-info)
	python scripts/RQ4/ERP/RQ4_group_analysis.py
	date > $@
	@echo "done with $@"
	@echo "---------"
	
#################################################

RQ3: $(strip $(DIR_RECEIPT))/RQ3_results

$(strip $(DIR_RECEIPT))/RQ3_results: $(strip $(DIR_RECEIPT))/ERP_process_data_step1 \
								  	 scripts/RQ3/ERP/RQ3_group_analysis.py
	$(print-target-and-prereq-info)
	python scripts/RQ3/ERP/RQ3_group_analysis.py
	date > $@
	@echo "done with $@"
	@echo "---------"
	
#################################################

RQ2: $(strip $(DIR_RECEIPT))/RQ2_results

$(strip $(DIR_RECEIPT))/RQ2_results_python: $(strip $(DIR_RECEIPT))/RQ2_results \
											scripts/RQ2/ERP/RQ2_mne_plots.py
	$(print-target-and-prereq-info)
	python scripts/RQ2/ERP/RQ2_mne_plots.py
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_results: $(strip $(DIR_RECEIPT))/RQ2_estimate_model \
									 scripts/RQ2/ERP/03_RQ2_model_diagnostics.R \
									 scripts/RQ2/ERP/04_RQ2_hypothesis_testing.R \
									 scripts/RQ2/ERP/05_RQ2_figures.R
	$(print-target-and-prereq-info)
	# first, check model diagnostics
	Rscript scripts/RQ2/ERP/03_RQ2_model_diagnostics.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/
	# second, check support for hypothesis
	Rscript scripts/RQ2/ERP/04_RQ2_hypothesis_testing.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/
	# third, prepare plots
	Rscript scripts/RQ2/ERP/05_RQ2_figures.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/
	date > $@
	@echo "done with $@"
	@echo "---------"
 
$(strip $(DIR_RECEIPT))/RQ2_estimate_model: $(strip $(DIR_RECEIPT))/RQ2_ERP_plots \
											scripts/RQ2/ERP/02_RQ2_parameter_estimation.R
	$(print-target-and-prereq-info)
	# estimation results are too large for GitHub, so they are saved outside the repository
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ2/
	Rscript scripts/RQ2/ERP/02_RQ2_parameter_estimation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_ERP_plots: $(strip $(DIR_RECEIPT))/RQ2_prep_data \
									   scripts/RQ2/ERP/01_RQ2_ERP_plots.R
	$(print-target-and-prereq-info)
	mkdir -p results_in_repo/RQ2/ERP/
	Rscript scripts/RQ2/ERP/01_RQ2_ERP_plots.R \
			$(strip $(PROJECT_SEED))
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_prep_data: $(strip $(DIR_RECEIPT))/ERP_process_data_step3 \
								       scripts/RQ2/ERP/00_RQ2_data_preparation.R
	$(print-target-and-prereq-info)
	mkdir -p data_in_repo/processed_data/RQ2/ERP/
	Rscript scripts/RQ2/ERP/00_RQ2_data_preparation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step3/ \
		    data_in_repo/processed_data/RQ2/ERP/
	date > $@
	@echo "done with $@"
	@echo "---------"

##################################################

RQ1: $(strip $(DIR_RECEIPT))/RQ1_results

$(strip $(DIR_RECEIPT))/RQ1_results_python: $(strip $(DIR_RECEIPT))/RQ1_results \
											scripts/RQ1/RQ1_mne_plots.py
	$(print-target-and-prereq-info)
	python scripts/RQ1/RQ1_mne_plots.py
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ1_results: $(strip $(DIR_RECEIPT))/RQ1_estimate_model \
									 scripts/RQ1/03_RQ1_model_diagnostics.R \
									 scripts/RQ1/04_RQ1_hypothesis_testing.R \
									 scripts/RQ1/05_RQ1_figures.R
	$(print-target-and-prereq-info)
	# first, check model diagnostics
	Rscript scripts/RQ1/03_RQ1_model_diagnostics.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/
	# second, check support for hypothesis
	Rscript scripts/RQ1/04_RQ1_hypothesis_testing.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/
	# third, prepare plots
	Rscript scripts/RQ1/05_RQ1_figures.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/
	date > $@
	@echo "done with $@"
	@echo "---------"
 

$(strip $(DIR_RECEIPT))/RQ1_estimate_model: $(strip $(DIR_RECEIPT))/RQ1_ERP_plots \
											scripts/RQ1/02_RQ1_parameter_estimation.R
	$(print-target-and-prereq-info)
	# estimation results are too large for GitHub, so they are saved outside the repository
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ1/
	Rscript scripts/RQ1/02_RQ1_parameter_estimation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/
	date > $@
	@echo "done with $@"
	@echo "---------"
 
$(strip $(DIR_RECEIPT))/RQ1_ERP_plots: $(strip $(DIR_RECEIPT))/RQ1_prep_data \
									   scripts/RQ1/01_RQ1_ERP_plots.R
	$(print-target-and-prereq-info)
	mkdir -p results_in_repo/RQ1/
	Rscript scripts/RQ1/01_RQ1_ERP_plots.R \
			$(strip $(PROJECT_SEED))
	date > $@
	@echo "done with $@"
	@echo "---------"
 
$(strip $(DIR_RECEIPT))/RQ1_prep_data: $(strip $(DIR_RECEIPT))/ERP_process_data_step3 \
								       scripts/RQ1/00_RQ1_data_preparation.R
	$(print-target-and-prereq-info)
	mkdir -p data_in_repo/processed_data/RQ1/
	Rscript scripts/RQ1/00_RQ1_data_preparation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step3/
	date > $@
	@echo "done with $@"
	@echo "---------"

######################################################

$(strip $(DIR_RECEIPT))/ERP_process_data_step3: $(strip $(DIR_RECEIPT))/ERP_process_data_step2 \
												scripts/ERP_preproc_step3.R
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step3/
	Rscript scripts/ERP_preproc_step3.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step2/ \
		    $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step3/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/ERP_process_data_step2: $(strip $(DIR_RECEIPT))/ERP_process_data_step1 \
												scripts/ERP_preproc_step2.py
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step2/
	python scripts/ERP_preproc_step2.py \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step1/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step2/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/ERP_process_data_step1: scripts/ERP_preproc_step1.py
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step1/
	python scripts/ERP_preproc_step1.py \
		   $(strip $(DIR_local_files))/data_outside_repo/original_data/eeg_BIDS/ \
		   $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step1/
	date > $@
	@echo "done with $@"
	@echo "---------"

##############################################
##############################################
# 
# define macros
# 
##############################################
##############################################

define print-target-and-prereq-info
	@echo "---------"
	@echo "---------"
	@echo "Target is:"
	echo $@
	@echo ""
	@echo "All prerequisites for this target are:"
	echo $^
	@echo ""
	@echo "The prerequisites newer than the target are:"
	echo $?
	@echo "---------"
endef