#!/bin/bash

modprobe null_blk

mkdir -p ${BLK_IO_CG} 
echo "252:0 1048576" > ${BLK_IO_CG}/blkio.throttle.read_bps_device
echo "252:0 1048576" > ${BLK_IO_CG}/blkio.throttle.write_bps_device
echo $$ > ${BLK_IO_CG}/cgroup.procs

echo 1 > /proc/sys/vm/block_dump
dd if=/dev/zero of=/dev/nullb0 bs=4k count=10 oflag=direct
dmesg -c
