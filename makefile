# for now, all has only test_make, to avoid everything building built by accident
# to build the analysis, you need to write 'make name_of_target' explicitly in the terminal
all: test_make ERP_Q1 TFR_Q2

#################################################
##
## set folders and other user specific info
##
#################################################

DIR_RECEIPT = zzz_receipts

# to process data, we need eeg_BIDS
# the eeg_BIDS data we received for this project is too large for GitHub
# this means we need to tell the scripts where to find these files outside of the repo

# you can choose to copy the files manually into original_data/eeg_BIDS/
DIR_eeg_BIDS = original_data/eeg_BIDS
# OR you can specify below the path to data for your user_name
# if you do not specify the path for your user_name, then the code will search for the raw data in original_data/eeg_BIDS/
user_name=$(shell whoami)
ifeq "$(strip $(user_name))" "anama"
	DIR_local_files = C:/Users/anama/Dropbox/Research/Data/EEG_Many_Pipelines/local_files
	DIR_eeg_BIDS = $(strip $(DIR_local_files))/data/original_data/eeg_BIDS
endif

test_make:
	@echo "Check if success_test_make.txt is created in DIR_RECEIPT"
	$(file > $(strip $(DIR_RECEIPT))/success_test_make.txt, 'make works just fine')
	@echo "Check if saved_from_test_make_py.txt is created in DIR_RECEIPT"
	python scripts/test_make.py $(strip $(DIR_RECEIPT))

#################################################
##
## from here on we have the analysis
##
#################################################

TFR_Q2: $(strip $(DIR_RECEIPT))/TFR_process_data_step2

$(strip $(DIR_RECEIPT))/TFR_process_data_step2: $(strip $(DIR_RECEIPT))/TFR_process_data_step1 \
										        scripts/TFR_preproc_step2.py
	$(print-target-and-prereq-info)
	python scripts/TFR_preproc_step2.py \
			"$(strip $(DIR_eeg_BIDS))/" \
			"$(strip $(DIR_local_files))/data/processed_data/TFR/step1/" \
			"$(strip $(DIR_local_files))/data/processed_data/TFR/step2/"
	date > $@
	@echo "done with $@"
	@echo "---------"


$(strip $(DIR_RECEIPT))/TFR_process_data_step1: scripts/TFR_preproc_step1.py \
	$(print-target-and-prereq-info)
	mkdir -p data/processed_data/TFR/step1
	python scripts/TFR_preproc_step1.py \
			"$(strip $(DIR_eeg_BIDS))/" \
			"$(strip $(DIR_local_files))/data/processed_data/TFR/step1"
	date > $@
	@echo "done with $@"
	@echo "---------"


# to answer Q1, we first need to process data
ERP_Q1: $(strip $(DIR_RECEIPT))/RQ1_process_data

$(strip $(DIR_RECEIPT))/RQ1_process_data: $(strip $(DIR_RECEIPT))/ERP_process_data_step3 \
										  scripts/RQ1/00_RQ1_data_preparation.R
	$(print-target-and-prereq-info)
	mkdir -p data/processed_data/ERP/RQ1
	Rscript scripts/RQ1/00_RQ1_data_preparation.R
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/ERP_process_data_step3: $(strip $(DIR_RECEIPT))/ERP_process_data_step2 \
												scripts/ERP_preproc_step3.R
	$(print-target-and-prereq-info)
	mkdir -p data/processed_data/ERP/step3
	Rscript scripts/ERP_preproc_step3.R
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/ERP_process_data_step2: $(strip $(DIR_RECEIPT))/ERP_process_data_step1 \
												scripts/ERP_preproc_step2.py
	$(print-target-and-prereq-info)
	mkdir -p data/processed_data/ERP/step2
	python scripts/ERP_preproc_step2.py
	date > $@
	@echo "done with $@"
	@echo "---------"

$(strip $(DIR_RECEIPT))/ERP_process_data_step1: scripts/ERP_preproc_step1.py
	$(print-target-and-prereq-info)
	python scripts/ERP_preproc_step1.py $(strip $(DIR_eeg_BIDS))/
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