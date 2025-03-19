#!/bin/bash

EXP_OPENED=8
CLOSED=12
FINISHED=12
blkzone reset /dev/nvme1n1

blkzone open   -o 0 -c 8        /dev/nvme1n1
blkzone open   -o 1310720 -c 10 /dev/nvme1n1
blkzone close  -o 1310720 -c 10 /dev/nvme1n1

blkzone open   -o 2621440 -c 12 /dev/nvme1n1
blkzone close  -o 2621440 -c 12 /dev/nvme1n1
blkzone finish -o 2621440 -c 12 /dev/nvme1n1

blkzone report /dev/nvme1n1

declare -a exp_open=($(nvme zns report-zones /dev/nvme1n1 --state=0x00 | grep -i exp_open | tr -s ' ' ' ' | cut -f 2 -d ' ' ))


declare empty=($(nvme zns report-zones /dev/nvme1n1 --state=0x00 | grep -i empty | tr -s ' ' ' ' | cut -f 2 -d ' '))

declare -a full=($(nvme zns report-zones /dev/nvme1n1 --state=0x00 | grep -i full | tr -s ' ' ' ' | cut -f 2 -d ' '))


run_test_exp_open()
{
	state=$1
	shift
	nr_desc=$1
	shift
	declare -a arr=("$@")

	echo "############# nr_zones = Decreasing number of zones and desc"
	for i in "${arr[@]}"; do
		echo "---------------------------------------------"
		nvme zns report-zones /dev/nvme1n1 --state=${state} \
						   --start-lba=${i}
	done

	read next 
	echo "############# nr_zones = Decreasing number of zones and 1 desc"
	for i in "${arr[@]}"; do
		echo "---------------------------------------------"
		nvme zns report-zones /dev/nvme1n1 --state=${state} \
						   --start-lba=${i} \
						   --desc=1
	done
	read next 

	echo "############# nr_zones = Decreasing number of zones and 4 desc"
	for i in "${arr[@]}"; do
		echo "---------------------------------------------"
		nvme zns report-zones /dev/nvme1n1 --state=${state} \
						   --start-lba=${i} \
						   --desc=4
	done
	read next 

	echo "############# constant nr_zones value for each slba and increaing desc"
	for i in "${arr[@]}"; do
		echo "---------------------------------------------"
		for ndesc in `seq 1 ${nr_desc}`; do
			nvme zns report-zones /dev/nvme1n1 --state=${state} \
							   --start-lba=${i} \
							   --desc=${ndesc}
		done
	done
	read next 

	echo "############# increasing nr_zones value for each slba and increaing desc"
	for i in "${arr[@]}"; do
		echo "---------------------------------------------"
		for ndesc in `seq 1 ${nr_desc}`; do
			nvme zns report-zones /dev/nvme1n1 --state=${state} \
							   --start-lba=${i} \
							   --desc=${ndesc} -p
		done
	done
}

#run_test_exp_open "0x03" ${EXP_OPENED} "${exp_open[@]}" 
#run_test_exp_open "0x01" ${CLOSED} "${empty[@]}" 
#run_test_exp_open "0x06" ${FINISHED} "${full[@]}" 
