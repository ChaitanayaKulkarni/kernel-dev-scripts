#!/bin/bash -x

umount /mnt/brd
dmesg -c > /dev/null
modprobe -r brd

lsmod | grep brd

#make -j $(nproc) M=drivers/block/ clean
make -j $(nproc) M=drivers/block modules #W=1 C=2 CHECK="smatch -p=kernel"

HOST=drivers/block/brd.ko
HOST_DEST=/lib/modules/`uname -r`/kernel/drivers/block/ 

cp ${HOST} ${HOST_DEST}/
ls -lrth $HOST_DEST/brd.ko

dmesg -c 
lsmod | grep brd

