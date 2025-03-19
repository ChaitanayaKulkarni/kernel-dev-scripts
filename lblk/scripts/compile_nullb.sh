#!/bin/bash -x

umount /mnt/nullb0
rmdir config/nullb/nullb*
dmesg -c > /dev/null
modprobe -r null_blk

lsmod | grep null_blk

make -j $(nproc) M=drivers/block/ clean
make -j $(nproc) M=drivers/block modules #W=1 C=2 #CHECK="smatch -p=kernel"

HOST=drivers/block/null_blk/
HOST_DEST=/lib/modules/`uname -r`/kernel/drivers/block/null_blk/  

cp ${HOST}/*.ko ${HOST_DEST}/
ls -lrth $HOST_DEST/null_blk.ko

#modprobe null_blk nr_devices=1
#modprobe null_blk zoned=1 zone_size=128 gb=1 bs=4096
sleep 1
#ls -l /dev/nullb*
#insmod drivers/block/null_copy_test.ko
dmesg -c 

