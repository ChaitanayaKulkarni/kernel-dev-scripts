#!/bin/bash

NN=$1
NQN=testnqn
set -x 
time nvme disconnect -n ${NQN}

for i in `shuf -i  1-$NN -n $NN`
do
	echo 0 > /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/enable
	rmdir /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}
done
rmdir config/nullb/nullb*
sleep 2
rm -fr /sys/kernel/config/nvmet/ports/1/subsystems/${NQN}
sleep 1
rmdir /sys/kernel/config/nvmet/ports/1

rmdir /sys/kernel/config/nvmet/subsystems/${NQN}
sleep 1
modprobe -r nvme_loop
modprobe -r nvme_fabrics
modprobe -r nvmet
modprobe -r nvme
umount /mnt/nvme0n1
umount /mnt/backend
modprobe -r null_blk

tree /sys/kernel/config
