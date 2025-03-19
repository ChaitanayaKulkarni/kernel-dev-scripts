#!/bin/bash

modprobe nvme
modprobe nvme-fabrics
modprobe nvmet
modprobe nvme_loop
umount /mnt/nvme0n1
sleep 1
#if [ "$#" -ne 1 ]; then
#	echo "nvme-pci ctrl is needed e.g. /dev/nvme0."
#	exit 1
#fi

#PT_DEV=$1
PT_DEV=/dev/nvme0
PT_CTRL=`echo $PT_DEV | cut -f 3 -d '/'`

echo $PT_CTRL

set -x
#echo "Creating passthru ctrl directory structure on target ..."
mkdir /sys/kernel/config/nvmet/passthru/${PT_CTRL}
sleep 1

echo "Initializing passthru ctrl path ..."
echo -n "${PT_DEV}" > /sys/kernel/config/nvmet/passthru/${PT_CTRL}/attr_ctrl_path 
sleep 1
echo 1 > /sys/kernel/config/nvmet/passthru/${PT_CTRL}/attr_enable
echo 1 > /sys/kernel/config/nvmet/passthru/${PT_CTRL}/attr_allow_any_host

#port 
mkdir /sys/kernel/config/nvmet/ports/1/
sleep 1
echo -n "loop" > /sys/kernel/config/nvmet/ports/1/addr_trtype
sleep 1

# connect
echo "Connecting passthru ctrl to the port "
ln -s /sys/kernel/config/nvmet/passthru/${PT_CTRL} /sys/kernel/config/nvmet/ports/1/subsystems/
sleep 1

nvme connect -t loop -n nvme0

sleep 3
nvme list | tr -s ' ' ' '
set +x
