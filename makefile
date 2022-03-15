all: test_make

test_make: success_test_make.txt

success_test_make.txt:
	@echo "Check if success_test_make.txt is created"
	$(file > success_test_make.txt, 'make works just fine')
	
process_data_for_ERP: scripts\preprocessing\ERP_preproc.py
