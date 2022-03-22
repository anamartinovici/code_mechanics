# for now, all has only test_make, to avoid everything building built by accident
# to build the analysis, you need to write 'make name_of_target' explicitly in the terminal
all: test_make ERP_Q1

test_make:
	@echo "Check if success_test_make.txt is created"
	$(file > success_test_make.txt, 'make works just fine')
	@echo "Check if saved_from_test_make_py.txt is created"
	python test_make.py

#################################################
#
# from here on we have the analysis
#
#################################################

# to answer Q1, we first need to process data
ERP_Q1: receipts/process_data_for_ERP

# to process data, we need eeg_BIDS
# the eeg_BIDS data we received for this project is too large for GitHub
# this means we need to tell the scripts where to find these files outside of the repo

# you can choose to copy the files manually into original_data/eeg_BIDS
DIR_eeg_BIDS = original_data/eeg_BIDS

# OR you can specify below the path to data for your user_name
# if you do not specify the path for your user_name, then the code will search for the raw data in original_data/eeg_BIDS
user_name=$(shell whoami)
ifeq "$(strip $(user_name))" "anama"
	DIR_eeg_BIDS = "C:/Users/anama/Dropbox/Research/Data/code_mechanics/data/original_data/eeg_BIDS"
endif

# how receipts work:
# if receipts/process_data_for_ERP exists, and the prerequisite
# (scripts/01_process_for_ERP_lowRAM.py) is not newer than the target 
# (receipts/process_data_for_ERP), then the 01... script is not executed
# this is great because it means you only process data if you need it
receipts/process_data_for_ERP: scripts/ERP_preproc_lowRAM.py
	$(print-target-and-prereq-info)
	python scripts/ERP_preproc_lowRAM.py $(strip $(DIR_eeg_BIDS))
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
	@echo ""
	@echo "Target is:"
	echo $@
	@echo ""
	@echo "All prerequisites for this target are:"
	echo $^
	@echo ""
	@echo "The prerequisites newer than the target are:"
	echo $?
	@echo ""
endef