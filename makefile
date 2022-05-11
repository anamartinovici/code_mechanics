all: initial_setup analysis

# targets in this file:
#		initial_setup
#			this needs to be built before any processing and analysis, to:
#			1. create the tmp and receipts directories
#			2. restore file timestamps, such that outdated targets are 
#			correctly detected and built
#			3. the .Rmd and reticulate combo is tested
# 
#		analysis 
#			this processes the data and performs the analysis for RQ1-RQ4

# to build the targets specified in `all`, type `make` in the terminal
# this will first build `initial_setup` and then `analysis`

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
# I STRONGLY!!!! advise you to keep this folder outside of the repository
# otherwise you need to copy paste the folder every time you get a fresh clone
# and there's a high risk you will lose data 
DIR_local_files = "Specify a PATH to your local_files directory"
# the default value is set in order to force you to specify a path
# see below for an example of how this path was specified
user_name=$(shell whoami)
# this is Ana's RSM PC
ifeq "$(strip $(user_name))" "STAFF+67003ama"
	DIR_local_files = D:/Dropbox/Research/Data/EEG_Many_Pipelines/code_mechanics
endif

initial_setup: scripts/get_path_to_local_files.R \
			   scripts/render_Rmd.R \
			   scripts/test_make.Rmd \
			   scripts/test_make.py
	@echo "before you can start the analysis, you first need to set up the repo"
	@echo "---------------"
	@echo "create the receipt and tmp folders within the repo"
	mkdir -p $(strip $(DIR_RECEIPT))/
	mkdir -p tmp/
	@echo "---------------"	
	@echo "restoring commit timestamps such that Make does not build based on git clone time"
	bash scripts/restore_file_timestamps.sh
	@echo "---------------"
	@echo "create an .Rdata file that store info about paths to local files"
	Rscript scripts/get_path_to_local_files.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))
	@echo "---------------"
	@echo "Check if test_make.html is created in tmp/"
	Rscript scripts/render_Rmd.R \
			scripts/test_make.Rmd \
			tmp/
	@echo "done with $@"
	@echo "---------"

#################################################
##
## from here on we have the analysis
##
#################################################

analysis: RQ1 RQ2 RQ3 RQ4

# to build a specific target, type "make name_of_target" in the terminal
# For example, analysis builds targets: RQ1, RQ2, RQ3, and RQ4. 
# If you want to build the targets associated with RQ1, type "make RQ1"

#################################################
##
## RQ4
##
#################################################

RQ4: RQ4_ERP RQ4_TFR

RQ4_ERP: $(strip $(DIR_RECEIPT))/RQ4_ERP_results_eq
RQ4_ERP: $(strip $(DIR_RECEIPT))/RQ4_ERP_results_NOTeq
RQ4_TFR: $(strip $(DIR_RECEIPT))/RQ4_TFR_analysis_eq	
RQ4_TFR: $(strip $(DIR_RECEIPT))/RQ4_TFR_analysis_NOTeq

$(strip $(DIR_RECEIPT))/RQ4_ERP_results_eq: $(strip $(DIR_RECEIPT))/ERP_process_data_step1 \
								  	        scripts/RQ4/ERP/RQ4_group_analysis_equalized.py \
								  	        scripts/RQ4/ERP/RQ4_group_analysis_equalized.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ4/ERP/equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ4/ERP/RQ4_group_analysis_equalized.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ4/ERP/equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ4_ERP_results_NOTeq: $(strip $(DIR_RECEIPT))/ERP_process_data_step1 \
								  	           scripts/RQ4/ERP/RQ4_group_analysis_not_equalized.py \
								  	           scripts/RQ4/ERP/RQ4_group_analysis_not_equalized.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ4/ERP/not_equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ4/ERP/RQ4_group_analysis_not_equalized.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ4/ERP/not_equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ4_TFR_analysis_NOTeq: $(strip $(DIR_RECEIPT))/RQ4_TFR_decomp_NOTeq \
										        scripts/RQ4/TFR/TFR_RQ4b_Analysis_not_equalized_events.py \
										        scripts/RQ4/TFR/TFR_RQ4b_Analysis_not_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p tmp/
	# note that this can use up to 50GB of RAM for 1000 permutations
	Rscript scripts/render_Rmd.R \
			scripts/RQ4/TFR/TFR_RQ4b_Analysis_not_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ4/TFR/not_equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ4_TFR_decomp_NOTeq: $(strip $(DIR_RECEIPT))/TFR_process_data_step1 \
										      scripts/RQ4/TFR/TFR_RQ4b_Decomposition_not_equalized_events.py \
										      scripts/RQ4/TFR/TFR_RQ4b_Decomposition_not_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ4/TFR/not_equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ4/TFR/TFR_RQ4b_Decomposition_not_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ4/TFR/not_equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ4_TFR_analysis_eq: $(strip $(DIR_RECEIPT))/RQ4_TFR_decomp_eq \
										     scripts/RQ4/TFR/TFR_RQ4b_Analysis_equalized_events.py \
										     scripts/RQ4/TFR/TFR_RQ4b_Analysis_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p tmp/
	# note that this can use up to 50GB of RAM for 1000 permutations
	Rscript scripts/render_Rmd.R \
			scripts/RQ4/TFR/TFR_RQ4b_Analysis_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ4/TFR/equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ4_TFR_decomp_eq: $(strip $(DIR_RECEIPT))/TFR_process_data_step1 \
										   scripts/RQ4/TFR/TFR_RQ4b_Decomposition_equalized_events.py \
										   scripts/RQ4/TFR/TFR_RQ4b_Decomposition_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ4/TFR/equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ4/TFR/TFR_RQ4b_Decomposition_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ4/TFR/equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

#################################################
##
## RQ3
##
#################################################

RQ3: RQ3_ERP RQ3_TFR

RQ3_ERP: $(strip $(DIR_RECEIPT))/RQ3_ERP_results_NOTeq
RQ3_ERP: $(strip $(DIR_RECEIPT))/RQ3_ERP_results_eq
RQ3_TFR: $(strip $(DIR_RECEIPT))/RQ3_TFR_analysis_NOTeq	
RQ3_TFR: $(strip $(DIR_RECEIPT))/RQ3_TFR_analysis_eq

$(strip $(DIR_RECEIPT))/RQ3_ERP_results_NOTeq: $(strip $(DIR_RECEIPT))/ERP_process_data_step1 \
								  	           scripts/RQ3/ERP/RQ3_group_analysis_not_equalized.py \
								  	           scripts/RQ3/ERP/RQ3_group_analysis_not_equalized.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ3/ERP/not_equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ3/ERP/RQ3_group_analysis_not_equalized.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ3/ERP/not_equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"
	
$(strip $(DIR_RECEIPT))/RQ3_ERP_results_eq: $(strip $(DIR_RECEIPT))/ERP_process_data_step1 \
								  	        scripts/RQ3/ERP/RQ3_group_analysis_equalized.py \
								  	        scripts/RQ3/ERP/RQ3_group_analysis_equalized.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ3/ERP/equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ3/ERP/RQ3_group_analysis_equalized.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ3/ERP/equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ3_TFR_analysis_NOTeq: $(strip $(DIR_RECEIPT))/RQ3_TFR_decomp_NOTeq \
										        scripts/RQ3/TFR/TFR_RQ3b_Analysis_not_equalized_events.py \
										        scripts/RQ3/TFR/TFR_RQ3b_Analysis_not_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p tmp/
	Rscript scripts/render_Rmd.R \
			scripts/RQ3/TFR/TFR_RQ3b_Analysis_not_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ3/TFR/not_equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ3_TFR_decomp_NOTeq: $(strip $(DIR_RECEIPT))/TFR_process_data_step1 \
										      scripts/RQ3/TFR/TFR_RQ3b_Decomposition_not_equalized_events.py \
										      scripts/RQ3/TFR/TFR_RQ3b_Decomposition_not_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ3/TFR/not_equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ3/TFR/TFR_RQ3b_Decomposition_not_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ3/TFR/not_equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ3_TFR_analysis_eq: $(strip $(DIR_RECEIPT))/RQ3_TFR_decomp_eq \
										     scripts/RQ3/TFR/TFR_RQ3b_Analysis_equalized_events.py \
										     scripts/RQ3/TFR/TFR_RQ3b_Analysis_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p tmp/
	Rscript scripts/render_Rmd.R \
			scripts/RQ3/TFR/TFR_RQ3b_Analysis_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ3/TFR/equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ3_TFR_decomp_eq: $(strip $(DIR_RECEIPT))/TFR_process_data_step1 \
										   scripts/RQ3/TFR/TFR_RQ3b_Decomposition_equalized_events.py \
										   scripts/RQ3/TFR/TFR_RQ3b_Decomposition_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ3/TFR/equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ3/TFR/TFR_RQ3b_Decomposition_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ3/TFR/equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

#################################################
##
## RQ2
##
#################################################

RQ2 : RQ2_ERP RQ2_TFR

RQ2_TFR: $(strip $(DIR_RECEIPT))/RQ2_TFR_analysis_eq
RQ2_TFR: $(strip $(DIR_RECEIPT))/RQ2_TFR_analysis_NOTeq

$(strip $(DIR_RECEIPT))/RQ2_TFR_analysis_NOTeq: $(strip $(DIR_RECEIPT))/RQ2_TFR_decomp_NOTeq \
										        scripts/RQ2/TFR/TFR_RQ2_Analysis_not_equalized_events.py \
										        scripts/RQ2/TFR/TFR_RQ2_Analysis_not_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p tmp/
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ2/TFR/not_equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ2/TFR/TFR_RQ2_Analysis_not_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/TFR/not_equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_TFR_decomp_NOTeq: $(strip $(DIR_RECEIPT))/TFR_process_data_step1 \
										      scripts/RQ2/TFR/TFR_RQ2_Decomposition_not_equalized_events.py \
										      scripts/RQ2/TFR/TFR_RQ2_Decomposition_not_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ2/TFR/not_equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ2/TFR/TFR_RQ2_Decomposition_not_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/TFR/not_equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"
	
$(strip $(DIR_RECEIPT))/RQ2_TFR_analysis_eq: $(strip $(DIR_RECEIPT))/RQ2_TFR_decomp_eq \
										     scripts/RQ2/TFR/TFR_RQ2_Analysis_equalized_events.py \
										     scripts/RQ2/TFR/TFR_RQ2_Analysis_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p tmp/
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ2/TFR/equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ2/TFR/TFR_RQ2_Analysis_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/TFR/equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_TFR_decomp_eq: $(strip $(DIR_RECEIPT))/TFR_process_data_step1 \
										   scripts/RQ2/TFR/TFR_RQ2_Decomposition_equalized_events.py \
										   scripts/RQ2/TFR/TFR_RQ2_Decomposition_equalized_events.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ2/TFR/equalized
	Rscript scripts/render_Rmd.R \
			scripts/RQ2/TFR/TFR_RQ2_Decomposition_equalized_events.Rmd \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/TFR/equalized/ 
	date > $@
	@echo "done with $@"
	@echo "---------"

RQ2_ERP: $(strip $(DIR_RECEIPT))/RQ2_ERP_plots
RQ2_ERP: $(strip $(DIR_RECEIPT))/RQ2_ERP_model_diagnostics
RQ2_ERP: $(strip $(DIR_RECEIPT))/RQ2_ERP_hypothesis_tests
RQ2_ERP: $(strip $(DIR_RECEIPT))/RQ2_ERP_figures

$(strip $(DIR_RECEIPT))/RQ2_ERP_figures: $(strip $(DIR_RECEIPT))/RQ2_ERP_estimate_model \
									     scripts/RQ2/ERP/05_RQ2_figures.R
	$(print-target-and-prereq-info)
	Rscript scripts/RQ2/ERP/05_RQ2_figures.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"informative"
	Rscript scripts/RQ2/ERP/05_RQ2_figures.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"weaklyinformative"
	Rscript scripts/RQ2/ERP/05_RQ2_figures.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"noninformative"
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_ERP_hypothesis_tests: $(strip $(DIR_RECEIPT))/RQ2_ERP_estimate_model \
									              scripts/RQ2/ERP/04_RQ2_hypothesis_testing.R
	$(print-target-and-prereq-info)
	Rscript scripts/RQ2/ERP/04_RQ2_hypothesis_testing.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"informative"
	Rscript scripts/RQ2/ERP/04_RQ2_hypothesis_testing.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"weaklyinformative"
	Rscript scripts/RQ2/ERP/04_RQ2_hypothesis_testing.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"noninformative"
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_ERP_model_diagnostics: $(strip $(DIR_RECEIPT))/RQ2_ERP_estimate_model \
											       scripts/RQ2/ERP/03_RQ2_model_diagnostics.R
	$(print-target-and-prereq-info)
	# model diagnostics need to be checked for all types of priors used in estimation
	Rscript scripts/RQ2/ERP/03_RQ2_model_diagnostics.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"informative"
	Rscript scripts/RQ2/ERP/03_RQ2_model_diagnostics.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"weaklyinformative"
	Rscript scripts/RQ2/ERP/03_RQ2_model_diagnostics.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"noninformative"
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_ERP_estimate_model: $(strip $(DIR_RECEIPT))/RQ2_ERP_prep_data \
											    scripts/RQ2/ERP/02_RQ2_parameter_estimation.R
	$(print-target-and-prereq-info)
	# estimation results are too large for GitHub, so they are saved outside the repository
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/
	Rscript scripts/RQ2/ERP/02_RQ2_parameter_estimation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"informative"
	Rscript scripts/RQ2/ERP/02_RQ2_parameter_estimation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"weaklyinformative"
	Rscript scripts/RQ2/ERP/02_RQ2_parameter_estimation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ2/ERP/ \
			"noninformative"
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_ERP_plots: $(strip $(DIR_RECEIPT))/RQ2_ERP_prep_data \
									   scripts/RQ2/ERP/01_RQ2_ERP_plots.R
	$(print-target-and-prereq-info)
	mkdir -p results_in_repo/RQ2/ERP/
	Rscript scripts/RQ2/ERP/01_RQ2_ERP_plots.R \
			$(strip $(PROJECT_SEED))
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ2_ERP_prep_data: $(strip $(DIR_RECEIPT))/ERP_process_data_step3 \
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
	
#################################################
##
## RQ1
##
#################################################

RQ1: $(strip $(DIR_RECEIPT))/RQ1_plots
RQ1: $(strip $(DIR_RECEIPT))/RQ1_model_diagnostics
RQ1: $(strip $(DIR_RECEIPT))/RQ1_hypothesis_tests
RQ1: $(strip $(DIR_RECEIPT))/RQ1_figures

$(strip $(DIR_RECEIPT))/RQ1_figures: $(strip $(DIR_RECEIPT))/RQ1_estimate_model \
									 scripts/RQ1/05_RQ1_figures.R
	$(print-target-and-prereq-info)
	# generate plots
	Rscript scripts/RQ1/05_RQ1_figures.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"informative"
	Rscript scripts/RQ1/05_RQ1_figures.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"weaklyinformative"
	Rscript scripts/RQ1/05_RQ1_figures.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"noninformative"
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ1_hypothesis_tests: $(strip $(DIR_RECEIPT))/RQ1_estimate_model \
											  scripts/RQ1/04_RQ1_hypothesis_testing.R
	$(print-target-and-prereq-info)
	# check support for hypothesis
	Rscript scripts/RQ1/04_RQ1_hypothesis_testing.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"informative"
	Rscript scripts/RQ1/04_RQ1_hypothesis_testing.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"weaklyinformative"
	Rscript scripts/RQ1/04_RQ1_hypothesis_testing.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"noninformative"
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ1_model_diagnostics: $(strip $(DIR_RECEIPT))/RQ1_estimate_model \
											   scripts/RQ1/03_RQ1_model_diagnostics.R
	$(print-target-and-prereq-info)
	# model diagnostics need to be checked for all types of priors used in estimation
	Rscript scripts/RQ1/03_RQ1_model_diagnostics.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"informative"
	Rscript scripts/RQ1/03_RQ1_model_diagnostics.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"weaklyinformative"
	Rscript scripts/RQ1/03_RQ1_model_diagnostics.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"noninformative"
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ1_estimate_model: $(strip $(DIR_RECEIPT))/RQ1_prep_data \
											scripts/RQ1/02_RQ1_parameter_estimation.R
	$(print-target-and-prereq-info)
	# estimation results are too large for GitHub, so they are saved outside the repository
	mkdir -p $(strip $(DIR_local_files))/results_outside_repo/RQ1/
	# we estimate the model 3 times, using different priors, to assess results sensitivity
	Rscript scripts/RQ1/02_RQ1_parameter_estimation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"informative"
	Rscript scripts/RQ1/02_RQ1_parameter_estimation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"weaklyinformative"
	Rscript scripts/RQ1/02_RQ1_parameter_estimation.R \
			$(strip $(PROJECT_SEED)) \
			$(strip $(DIR_local_files))/results_outside_repo/RQ1/ \
			"noninformative"
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/RQ1_plots: $(strip $(DIR_RECEIPT))/RQ1_prep_data \
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

#################################################
##
## process data for TFR
##
#################################################

$(strip $(DIR_RECEIPT))/TFR_process_data_step1: scripts/TFR_preproc_step1.py \
												scripts/TFR_preproc_step1.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/
	Rscript scripts/render_Rmd.R \
			scripts/TFR_preproc_step1.Rmd \
			$(strip $(DIR_local_files))/data_outside_repo/processed_data/TFR/step1/
	date > $@
	@echo "done with $@"
	@echo "---------"

#################################################
##
## process data for ERP
##
#################################################

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
												scripts/ERP_preproc_step2.py \
												scripts/ERP_preproc_step2.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step2/
	Rscript scripts/render_Rmd.R \
			scripts/ERP_preproc_step2.Rmd \
			$(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step2/
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/ERP_process_data_step1: scripts/ERP_preproc_step1.py \
												scripts/ERP_preproc_step1.Rmd
	$(print-target-and-prereq-info)
	mkdir -p $(strip $(DIR_local_files))/data_outside_repo/processed_data/ERP/step1/
	Rscript scripts/render_Rmd.R \
			scripts/ERP_preproc_step1.Rmd \
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

