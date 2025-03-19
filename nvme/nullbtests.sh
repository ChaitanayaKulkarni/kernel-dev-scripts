#!/bin/bash -x

umount /mnt/test
rmdir config/nullb/nullb*

let NN=$1-1

modprobe -r null_blk
#modprobe null_blk nr_devices=10 gb=1
modprobe null_blk nr_devices=0

echo loading devices
for i in `seq 0 $NN`
do
	NULLB_DIR=config/nullb/nullb${i}
	mkdir config/nullb/nullb${i}
	if [ $? -ne 0 ]; then
		exit $?
	fi

	echo 1 > config/nullb/nullb${i}/memory_backed
	echo 512 > config/nullb/nullb${i}/blocksize 
	echo 1024 > config/nullb/nullb${i}/size 
	#echo 1 > config/nullb/nullb${i}/zoned
	#echo 128 > config/nullb/nullb${i}/zone_size
	#echo 8 > config/nullb/nullb${i}/zone_nr_conv
	echo 1 > config/nullb/nullb${i}/power

	read next
	IDX=`cat config/nullb/nullb${i}/index`
	echo -n " $i INDEX $IDX "
	lsblk
	sleep .50
done

lsblk | grep null | sort 
sleep 1
dmesg -c

lsblk | grep null
echo "waiting "

read n
<<COMM
for i in `seq 0 $NN`
do
	fio fio/verify.fio --filename=/dev/nullb${i} --output=/tmp/fio.log
	grep err /tmp/fio.log

	mkfs.btrfs /dev/nullb${i}
	mount /dev/nullb${i} /mnt/test
	fio fio/verify.fio --filename=/mnt/test/nullb${i} --output=/tmp/fio.log
	grep err /tmp/fio.log
	umount /mnt/test
done

echo deleteing devices
for i in `seq 0 $NN`; do rmdir config/nullb/nullb${i}; done

modprobe -r null_blk
COMM
