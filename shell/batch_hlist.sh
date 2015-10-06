#!/bin/bash
#
# Runs HList on each word file, logging the results.

ROOT_DIR=/imaging/cw04/Neurolex/Lexpro/Analysis_DNN/Building_models/HTK_versions/HTK-Neurolex-2015-07-23
LOG_DIR=/imaging/cw04/Neurolex/Lexpro/Analysis_DNN/Building_models/scratch_htk/bottleneck_log

# Get the list of all mlp files in the data directory
for FILE_PATH in $ROOT_DIR/data/bn26d/test/*.mlp
do
	# Get the file name itself (minus its path)
	FILE_NAME=${FILE_PATH##*/}
	
	# Get the base of the file name (minus the extension)
	BASE_NAME=${FILE_NAME%.mlp}
	
	# Name of the log file for running HList on this word
	LOG_NAME=$LOG_DIR/$BASE_NAME.log
	
	echo "$LOG_NAME"
	$ROOT_DIR/bin.linux/HList -h $FILE_PATH > $LOG_DIR/$BASE_NAME.log
	
done
