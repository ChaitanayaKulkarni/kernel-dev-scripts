#!/bin/bash

NQN=$1
set -x 
time nvme disconnect -n ${NQN}

for i in /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/*
do
	echo 0 > ${i}/enable
	rmdir ${i}
done

#sleep 2
rm -fr /sys/kernel/config/nvmet/ports/1/subsystems/${NQN}
#sleep 1
rmdir /sys/kernel/config/nvmet/ports/1

rmdir /sys/kernel/config/nvmet/subsystems/${NQN}
#sleep 1
rmdir config/nullb/nullb*
modprobe -r nvme_loop
modprobe -r nvme_fabrics
modprobe -r nvmet
modprobe -r nvme
modprobe -r null_blk
umount /mnt/nvme0n1
umount /mnt/backend

tree /sys/kernel/config
