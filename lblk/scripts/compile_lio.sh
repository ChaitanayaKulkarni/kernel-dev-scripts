#!/bin/bash -x

clear_dmesg &

targetcli clearconfig confirm=True
rmdir config/target/iscsi 
rmdir config/target/loopback

modprobe -r iscsi_target_mod
modprobe -r tcm_loop
modprobe -r target_core_file
modprobe -r target_core_pscsi
modprobe -r target_core_iblock
modprobe -r target_core_user
modprobe -r target_core_mod

lsmod | grep target
! make -j $(nproc) M=drivers/target modules && exit 1

TARGET=drivers/target
TARGET_DEST=/lib/modules/`uname -r`/kernel/drivers/target/

TARGET_LOOPBACK=drivers/target/loopback
TARGET_LOOPBACK_DEST=/lib/modules/`uname -r`/kernel/drivers/target/loopback

TARGET_ISCSI=drivers/target/iscsi/
TARGET_ISCSI_DEST=/lib/modules/`uname -r`/kernel/drivers/target/iscsi

cp ${TARGET}/*.ko ${TARGET_DEST}/
cp ${TARGET_LOOPBACK}/*.ko ${TARGET_LOOPBACK_DEST}/
cp ${TARGET_ISCSI}/*.ko ${TARGET_ISCSI_DEST}/

find ${TARGET_DEST} -name \*ko | xargs ls -l

modprobe target_core_file
modprobe target_core_pscsi
modprobe target_core_iblock
modprobe target_core_user
modprobe target_core_mod

lsmod | grep target_core

tree config/target
targetcli restoreconfig ./lio.json 
lsscsi 
