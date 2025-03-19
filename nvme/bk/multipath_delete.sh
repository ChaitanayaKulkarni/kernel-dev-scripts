#!/bin/bash

NN=2
set -x 
time nvme disconnect -n fs

for i in `shuf -i  1-$NN -n $NN`
do
	echo 0 > /sys/kernel/config/nvmet/subsystems/fs/namespaces/${i}/enable
	rmdir /sys/kernel/config/nvmet/subsystems/fs/namespaces/${i}
done
sleep 2
rm -fr /sys/kernel/config/nvmet/ports/1/subsystems/fs
rm -fr /sys/kernel/config/nvmet/ports/2/subsystems/fs
rmdir /sys/kernel/config/nvmet/ports/1/ana_groups/2
rmdir /sys/kernel/config/nvmet/ports/2/ana_groups/2
rmdir /sys/kernel/config/nvmet/ports/1
rmdir /sys/kernel/config/nvmet/ports/2
rmdir /sys/kernel/config/nvmet/subsystems/fs
sleep 1
modprobe -r nvme_loop
modprobe -r nvme_fabrics
modprobe -r nvmet
modprobe -r nvme
