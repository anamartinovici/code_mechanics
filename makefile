all: test_make

test_make:
	@echo "Check if success_test_make.txt is created"
	$(file > success_test_make.txt, 'make works just fine')
	@echo "Check if saved_from_test_make_py.txt is created"
	python test_make.py

# I need to copy the eeg_BIDS into original_data
# for now, this is a manual operation
# in the future, this will be done by downloading from the Research Drive

process_data_for_ERP: scripts/01_ERP_processing.py
	python scripts/01_ERP_processing.py
