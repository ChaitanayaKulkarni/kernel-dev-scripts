#!/bin/bash -x

dmesg -c > /dev/null
targetcli clearconfig confirm=True

HOST=drivers/target/
HOST_DEST=/lib/modules/`uname -r`/kernel/drivers/target/  

rmmod $HOST_DEST/target_core_iblock.ko 
rmmod $HOST_DEST/target_core_file.ko 

lsmod | grep null_blk

#make -j $(nproc) M=drivers/block/ clean
make -j $(nproc) M=drivers/target modules #W=1 C=2 CHECK="smatch -p=kernel"

cp ${HOST}/*.ko ${HOST_DEST}/
ls -lrth $HOST_DEST/*.ko

insmod $HOST_DEST/target_core_iblock.ko 
insmod $HOST_DEST/target_core_file.ko 
sleep 1
lsmod | grep target
dmesg -c 

targetcli restoreconfig savefile=lio.json
sleep 1
lsscsi

