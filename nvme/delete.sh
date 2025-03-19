#!/bin/bash 

set -x 
NQN=testnqn
time nvme disconnect -n ${NQN}

rm -fr /sys/kernel/config/nvmet/ports/1/subsystems/*
rmdir /sys/kernel/config/nvmet/ports/1

for subsys in /sys/kernel/config/nvmet/subsystems/*
do
	for ns in ${subsys}/namespaces/*
	do
		echo 0 > ${ns}/enable
		rmdir ${ns}
	done
	rmdir ${subsys}
done


rmdir config/nullb/nullb*

umount /mnt/nvme0n1
umount /mnt/backend

#modprobe -r nvme_loop
#modprobe -r nvme_fabrics
#modprobe -r nvmet
#modprobe -r nvme
#modprobe -r null_blk

echo "############################## DELETE #############################"
for mod in nvme_loop nvmet nvme_tcp nvme_fabrics nvme nvme_core \
		nvme_keryring nvme_auth null_blk;
do
	modprobe -r "${mod}"
	lsmod | grep nvme
done

tree /sys/kernel/config
