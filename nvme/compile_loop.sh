#!/bin/bash -x

FILE="/mnt/nvme0n1/nvme1n1"
NVME_MNT="/mnt/nvme0n1"
LOOP_MNT="/mnt/loop0"

unload_loop()
{
	umount ${LOOP_MNT}
	losetup -D
	sleep 3
	rmmod loop
	lsmod | grep loop
}

unload_nvme()
{
	umount ${NVME_MNT}
	sleep 3
	rmmod ext4
	lsmod | grep ext4
#	modprobe -r nvme
}

compile_loop()
{
	#make -j $(nproc) M=drivers/block/ clean
	make -j $(nproc) M=drivers/block modules

	HOST=drivers/block/
	HOST_DEST=/lib/modules/`uname -r`/kernel/drivers/block
	cp ${HOST}/loop.ko ${HOST_DEST}/

	make -j $(nproc) M=fs/ext4 modules
	HOST=fs/ext4/
	HOST_DEST=/lib/modules/`uname -r`/kernel/fs/ext4
	cp ${HOST}/ext4.ko ${HOST_DEST}/
}

load_nvme()
{
#	modprobe nvme #poll_queues=$(nproc)
#	sleep 1
	insmod fs/ext4/ext4.ko
	mkfs.ext4 /dev/nvme0n1 
	mount /dev/nvme0n1 ${NVME_MNT}
	dd if=/dev/zero of=${FILE} count=1 bs=700M
	mount | grep nvme
}

load_loop()
{
	insmod drivers/block/loop.ko max_loop=1
	/root/util-linux/losetup --direct-io=on /dev/loop0 ${FILE} 
	/root/util-linux/losetup
	sleep 1
	ls -l /dev/loop*
	dmesg -c 
}

test_assign()
{
	mkfs.ext4 /dev/loop0
	mount /dev/loop0 ${LOOP_MNT}
	mount | grep loop0
	time ./test
}

unload_loop
unload_nvme
compile_loop
#load_nvme
#load_loop
#test_assign
