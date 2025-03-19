#!/bin/bash -x

FILE="./loop"
LOOP_MNT="/mnt/loop"
NN=$1

unload_loop()
{
	for i in `shuf -i 1-$NN -n $NN`
	do 
		umount ${LOOP_MNT}${i}
		rm -fr ${FILE}${i}
	done
	losetup -D
	sleep 3
	rmmod loop
	modprobe -r loop 
	lsmod | grep loop
	for i in `shuf -i 1-$NN -n $NN`
	do 
		rm -fr ${FILE}${i}
	done
	rm -fr /mnt/loop*
	dmesg -c
}

compile_loop()
{
	git apply wip.diff
	make -j $(nproc) M=drivers/block modules
	HOST=drivers/block/
	HOST_DEST=/lib/modules/`uname -r`/kernel/drivers/block
	cp ${HOST}/loop.ko ${HOST_DEST}/
}

load_loop()
{
	for i in `shuf -i  1-$NN -n $NN`
	do 
		mkdir -p /mnt/loop${i}
		truncate -s 2048M ${FILE}${i}
		/mnt/data/util-linux/losetup --direct-io=on /dev/loop${i} ${FILE}${i} 
		/mnt/data/util-linux/losetup
		sleep 1
		mkfs.xfs -f /dev/loop${i}
		mount /dev/loop${i} /mnt/loop${i}
		for attr in offset sizelimit autoclear partscan dio
		do
			echo -n "cat /sys/block/loop${i}/loop/${attr} : "
			cat /sys/block/loop${i}/loop/${attr}
			cat /sys/block/loop${i}/queue/nr_requests
		done
	done
	mount | grep loop
}

run_verify()
{
	for i in `shuf -i 1-$NN -n $NN`
	do
		fallocate -o 0 -l $((500*1024*1024)) /mnt/loop${i}/testfile
		fio fio/verify.fio --filename=/mnt/loop${i}/testfile
	done 
}

unload_loop
compile_loop
insmod drivers/block/loop.ko max_loop=$((${NN}+1)) #hw_queue_depth=64
load_loop
dmesg -c
run_verify
df -h /mnt/loop*
unload_loop
dmesg -c 
