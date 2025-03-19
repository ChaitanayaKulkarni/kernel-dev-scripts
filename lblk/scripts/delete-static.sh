#!/bin/bash

set -x 
nvme disconnect -n fs
#sleep 2
rm -fr /sys/kernel/config/nvmet/ports/1/subsystems/fs
#sleep 1
rmdir /sys/kernel/config/nvmet/ports/1


for i in 1 #2 3 4 5 6 7 8 9 10
do
	echo 0 > /sys/kernel/config/nvmet/subsystems/fs/namespaces/${i}/enable
	rmdir /sys/kernel/config/nvmet/subsystems/fs/namespaces/${i}
	sleep 1
done
rmdir /sys/kernel/config/nvmet/subsystems/fs
sleep 1
modprobe -r nvme_loop
modprobe -r nvme_fabrics
modprobe -r nvmet
umount /mnt/nvme0n1
umount /mnt/backend
echo 0 > config/nullb/nullb0/power
rmdir config/nullb/nullb0
