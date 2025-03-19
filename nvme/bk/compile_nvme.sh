#!/bin/bash -x

clear_dmesg &
umount /mnt/nvme0n1

#./passthru_clear.sh
#./delete.sh
modprobe -r nvme-fabrics
modprobe -r nvme_loop
modprobe -r nvmet
modprobe -r nvme
sleep 1
modprobe -r nvme-core

lsmod | grep nvme

git apply ./all-fixes.diff
sleep 1
git diff
sleep 1

#make -j $(nproc) M=drivers/nvme/target/ clean
make -j $(nproc) M=drivers/nvme/ modules
#
HOST=drivers/nvme/host
TARGET=drivers/nvme/target
HOST_DEST=/lib/modules/`uname -r`/kernel/drivers/nvme/host/
TARGET_DEST=/lib/modules/`uname -r`/kernel/drivers/nvme/target/

cp ${HOST}/*.ko ${HOST_DEST}/
cp ${TARGET}/*.ko ${TARGET_DEST}/
ls -lrth $HOST_DEST $TARGET_DEST/ 

modprobe nvme #poll_queues=$(nproc)
#dmesg -c

git co drivers/nvme/target/loop.c 
