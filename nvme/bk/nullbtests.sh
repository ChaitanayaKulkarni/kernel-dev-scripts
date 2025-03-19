#!/bin/bash -x

rmdir config/nullb/nullb*

NN=$1

modprobe -r null_blk
#modprobe null_blk nr_devices=10 gb=1
modprobe null_blk nr_devices=0

echo loading devices
for i in `seq 0 $NN`
do
	NULLB_DIR=config/nullb/nullb${i}
	mkdir config/nullb/nullb${i}

	echo 1 > config/nullb/nullb${i}/memory_backed
	echo 512 > config/nullb/nullb${i}/blocksize 
	echo 2048 > config/nullb/nullb${i}/size 
	echo 1 > config/nullb/nullb${i}/zoned
	echo 128 > config/nullb/nullb${i}/zone_size
	echo 8 > config/nullb/nullb${i}/zone_nr_conv
	echo 1 > config/nullb/nullb${i}/power
	IDX=`cat config/nullb/nullb${i}/index`
	echo -n " $i "
	sleep .50
done

lsblk | grep null | sort 
sleep 1
dmesg -c

lsblk | grep null
echo "waiting "

read n
echo deleteing devices
for i in `seq 0 $NN`; do rmdir config/nullb/nullb${i}; done

modprobe -r null_blk
