# for now, all has only test_make, to avoid everything building built by accident
# to build the analysis, you need to write 'make name_of_target' explicitly in the terminal
all: test_make ERP_process_data TFR_process_data

#################################################
##
## set folders and other user specific info
##
#################################################

DIR_RECEIPT = zzz_receipts

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
ifeq "$(strip $(user_name))" "anama"
	DIR_local_files = C:/Users/anama/Dropbox/Research/Data/EEG_Many_Pipelines/local_files
endif

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

TFR_process_data: $(strip $(DIR_RECEIPT))/TFR_process_data_step2

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

# to answer Q1, we first need to process data
ERP_process_data: $(strip $(DIR_RECEIPT))/ERP_process_data_step2

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