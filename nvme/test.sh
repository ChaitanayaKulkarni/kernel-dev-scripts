#!/bin/bash

#set -x 
#rmmod host/test_verify.ko
#./delete.sh
#./compile_nullb.sh
#./nvme_compile.sh
#./bdev.sh 0
#set +x 


for cv_zones in 100 200 300 400 500 600 700 800 900;                                               
do
	echo "-----------------------------------"
	modprobe null_blk zoned=1 zone_nr_conv=$cv_zones
	echo -n "/sys/block/nullb0/queue/nr_conv_zones = ";
	cat /sys/block/nullb0/queue/nr_conv_zones; 
	echo -n "/sys/block/nullb0/queue/nr_seq_zones  = ";
	cat /sys/block/nullb0/queue/nr_seq_zones;
	modprobe -r null_blk
done 

