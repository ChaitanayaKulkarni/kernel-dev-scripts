#!/bin/bash -x

dmesg -c > /dev/null
modprobe -r virtio_blk

lsmod | grep virtio_blk

#make -j $(nproc) M=drivers/block/ clean
make -j $(nproc) M=drivers/block modules #W=1 C=2 CHECK="smatch -p=kernel"

#HOST=drivers/block/
#HOST_DEST=/lib/modules/`uname -r`/kernel/drivers/block/

#cp ${HOST}/virtio_blk.ko ${HOST_DEST}/
#ls -lrth $HOST_DEST/virtio_blk.ko

read next

#modprobe virtio_blk 
insmod drivers/block/virtio_blk.ko
sleep 1
#echo 1 >  /sys/block/vda/io-timeout-fail
#sleep 1
#cat /sys/block/vda/io-timeout-fail
dmesg -c 

