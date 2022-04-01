# git does not record the timestamp for the files
# when I clone the repo on a new device, the files have the timestamp of 
#	when they were saved/downloaded/cloned on the device
# this means that filename_A will be downloaded before filename_B
#	and as a result, the Makefile will see filename_B as more recent than filename_A
# this can be an issue if I use receipts to indicate prerequisites for long computations
# the code below changes the timestamp to match the time of the previous commit
#	this can be risky and lead to issues, but it's the best option for now
# to avoid problems, we need to ALWAYS!!! run `make` before commit and push
#	this way, all targets that need to be build are made before commit and push
#	so the date of the commit is informative of when the target was last built

git ls-tree -r --name-only HEAD | while read filename; do
  unixtime=$(git log -1 --format="%at" -- "${filename}")
  touchtime=$(date -d @$unixtime +'%Y%m%d%H%M.%S')
  touch -t ${touchtime} "${filename}"
done