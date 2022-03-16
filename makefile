all: test_make

test_make:
	@echo "Check if success_test_make.txt is created"
	$(file > success_test_make.txt, 'make works just fine')
	@echo "Check if saved_from_test_make_py.txt is created"
	python test_make.py

# I need to copy the eeg_BIDS into original_data
# for now, this is a manual operation
# in the future, this will be done by downloading from the Research Drive

process_data_for_ERP: receipts/process_data_for_ERP

# how receipts work:
# if receipts/process_data_for_ERP exists, and the prerequisite
# (scripts/01_process_for_ERP_lowRAM.py) is not newer than the target 
# (receipts/process_data_for_ERP), then the 01... script is not executed
# this is great because it means you only process data if you need it
receipts/process_data_for_ERP: scripts/01_process_for_ERP_lowRAM.py
	python scripts/01_process_for_ERP_lowRAM.py
	date > $@
	@echo "done with $@"

# check dropped epochs for 002 - the script now drops one extra compared to Antonio's results
# check dropped for  007

process_data_for_ERP_highRAM: receipts/process_data_for_ERP_highRAM

receipts/process_data_for_ERP_highRAM: scripts/ERP_preproc.py
	python scripts/ERP_preproc.py
	date > $@
	@echo "done with $@"
