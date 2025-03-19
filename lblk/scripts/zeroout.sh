#!/bin/bash

IDX=-1
DEV=""

print_blk()
{
	local blk_size=$1

	for i in `seq 0 9`
	do
		let skip=${i}*${blk_size}
		od -A d  --skip-bytes=${skip} --read-bytes=16 -c ${DEV}
	done 
	echo "------------------------------------------------------"
}

do_odd()
{
	local blk_size=$1

	dd if=./pattern of=${DEV} bs=${blk_size} count=20 2>&1 > /dev/null
	print_blk ${blk_size}
	for i in 1 3 5 7 9
	do
		let offset=${i}*${blk_size}
		blkdiscard -z -o ${offset} -l ${blk_size} ${DEV}
	done 
	print_blk ${blk_size}
}

do_even()
{
	local blk_size=$1
	dd if=./pattern of=${DEV} bs=${blk_size} count=20 2>&1 > /dev/null
	print_blk ${blk_size}
	for i in 0 2 4 6 8
	do
		let offset=${i}*${blk_size}
		blkdiscard -z -o ${offset} -l ${blk_size} ${DEV}
	done 
	print_blk ${blk_size}
}

do_mkfs()
{
	mkfs.ext2 /dev/nullb0
	mount /dev/nullb0 /mnt/nullb0
	mount | grep null
	dmesg -c
	fio fio/verify.fio --filename=/mnt/nullb0/testfile
	umount /mnt/nullb0

	mkfs.ext4 -F /dev/nullb0
	mount /dev/nullb0 /mnt/nullb0
	mount | grep null
	dmesg -c
	fio fio/verify.fio --filename=/mnt/nullb0/testfile
}

cleanup()
{
	umount /mnt/nullb0
	echo 0 > config/nullb/nullb0/power
	rmdir config/nullb/nullb0
}

config_nullb_blk_write_zeroes()
{
	local blk_size=$1

	modprobe -r null_blk
	modprobe null_blk gb=5 nr_devices=0

	dmesg -c > /dev/null

	mkdir config/nullb/nullb0
	tree config/nullb/nullb0

	echo $blk_size > config/nullb/nullb0/blocksize 
	echo 1 > config/nullb/nullb0/memory_backed
	echo 1 > config/nullb/nullb0/write_zeroes
	echo 1 > config/nullb/nullb0/power

	IDX=`cat config/nullb/nullb0/index`
	sleep 1

	if [ ! -b /dev/nullb${IDX} ]; then
                echo "null_blk block size ${blk_size} config failed"
		cleanup
		exit 1;
	fi
	DEV=/dev/nullb${IDX}
	lsblk | grep ${DEV}

}

main()
{

	for blk_size in 512 1024 2048 4096
	do
		echo "#################### BLKISZ ${blk_size} #####################"
		config_nullb_blk_write_zeroes $blk_size

		echo "ODD:- "
		do_odd ${blk_size}

		echo "EVEN:- "
		do_even ${blk_size}
		echo "MKFS:-"
		do_mkfs

		cleanup
		echo ""; echo ""; echo ""; echo "";
	done
}

main
