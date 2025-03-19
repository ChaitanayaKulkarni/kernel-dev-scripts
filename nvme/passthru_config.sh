#!/bin/bash

modprobe nvme
modprobe nvme-fabrics
modprobe nvmet
modprobe nvme_loop
umount /mnt/nvme0n1
sleep 5

PT_DEV=$1

set -x
#echo "Creating passthru ctrl directory structure on target ..."
mkdir /sys/kernel/config/nvmet/subsystems/pt-nqn
sleep 1

echo "Initializing passthru ctrl path ..."
echo -n "${PT_DEV}" > /sys/kernel/config/nvmet/subsystems/pt-nqn/passthru/device_path
sleep 1
echo 1 > /sys/kernel/config/nvmet/subsystems/pt-nqn/passthru/enable
echo 1 > /sys/kernel/config/nvmet/subsystems/pt-nqn/attr_allow_any_host

#port
mkdir /sys/kernel/config/nvmet/ports/1/
sleep 1
echo -n "loop" > /sys/kernel/config/nvmet/ports/1/addr_trtype
sleep 1

# connect
echo "Connecting passthru ctrl to the port "
ln -s /sys/kernel/config/nvmet/subsystems/pt-nqn /sys/kernel/config/nvmet/ports/1/subsystems/
sleep 1

nvme connect -t loop -n pt-nqn
sleep 1
nvme list | tr -s ' ' ' '
set +x


