#!/bin/bash -x

clear_dmesg &
umount /mnt/nvme0n1

rmmod host/tets_verify.ko
modprobe -r nvme-fabrics
modprobe -r nvme_loop
modprobe -r nvmet
modprobe -r nvme
sleep 1
modprobe -r nvme-core

lsmod | grep nvme

#make -j $(nproc) M=drivers/nvme/target/ clean
make -j $(nproc) M=drivers/nvme/ modules #2>&1 | grep -v  "but does not import it"   #W=1 C=2 CHECK="smatch -p=kernel" 
#
HOST=drivers/nvme/host
TARGET=drivers/nvme/target
HOST_DEST=/lib/modules/`uname -r`/kernel/drivers/nvme/host/
TARGET_DEST=/lib/modules/`uname -r`/kernel/drivers/nvme/target/

cp ${HOST}/*.ko ${HOST_DEST}/
cp ${TARGET}/*.ko ${TARGET_DEST}/
ls -lrth $HOST_DEST $TARGET_DEST/ 

modprobe nvme #poll_queues=12
#modprobe nvme
dmesg -c
#sleep 2
#mount /dev/nvme0n1 /mnt/nvme0n1
#clear_dmesg
