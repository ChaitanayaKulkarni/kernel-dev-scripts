#!/bin/bash -x

rmdir config/nullb/nullb*

let NN=$1-1

modprobe -r null_blk
#modprobe null_blk nr_devices=10 gb=1
modprobe null_blk nr_devices=0 queue_mode=0

echo loading devices
for i in `seq 0 $NN`
do
	NULLB_DIR=config/nullb/nullb${i}
	mkdir config/nullb/nullb${i}

#	echo 1 > config/nullb/nullb${i}/zoned
	cat config/nullb/nullb${i}/zoned
	echo 256 > config/nullb/nullb${i}/zone_size
	echo 0 > config/nullb/nullb${i}/zone_nr_conv

	echo 1 > config/nullb/nullb${i}/memory_backed
	echo 4096 > config/nullb/nullb${i}/blocksize 
	echo 20480 > config/nullb/nullb${i}/size
#	echo 1 > config/nullb/nullb${i}/write_zeroes
	cat config/nullb/nullb${i}/zone_reset_all
	echo 0 > config/nullb/nullb${i}/zone_reset_all
	echo 1 > config/nullb/nullb${i}/discard
#echo 1 > config/nullb/nullb${i}/max_discard_sectors
#	echo 1 > config/nullb/nullb${i}/max_write_zeroes_sectors
#	echo 1 > config/nullb/nullb${i}/discard 
#	cat config/nullb/nullb${i}/discard 
# BIO mode 
	echo 0 > config/nullb/nullb${i}/queue_mode
	cat config/nullb/nullb${i}/queue_mode
	echo 1 > config/nullb/nullb${i}/power
	IDX=`cat config/nullb/nullb${i}/index`
	echo -n " $i "
	sleep .50
done

lsblk | grep null | sort 
sleep 1
dmesg -c
lsblk | grep null

#for i in `seq 0 $NN`; do fio fio/verify.fio --zonemode=zbd --filename=/dev/nullb${i}; done
#for i in `seq 0 $NN`; do fio fio/verify.fio --filename=/dev/nullb${i}; done
#blkzone reset /dev/nullb0
dmesg -c
#read next
#echo deleteing devices
#for i in `seq 0 $NN`; do time rmdir config/nullb/nullb${i}; done
#modprobe -r null_blk
