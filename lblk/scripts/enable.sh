#!/bin/bash
set -x
mkdir /sys/kernel/config/nvmet/passthru/nvme0
read next
echo -n "nvme0" > /sys/kernel/config/nvmet/passthru/nvme0/attr_ctrl_path 
read next

echo 1 > /sys/kernel/config/nvmet/passthru/nvme0/attr_enable
echo 1 > /sys/kernel/config/nvmet/passthru/nvme0/attr_allow_any_host

read next

ln -s /sys/kernel/config/nvmet/passthru/nvme0 /sys/kernel/config/nvmet/ports/1/subsystems/
read next

echo "transport=loop,nqn=nvme0" > /dev/nvme-fabrics 

sleep 3
nvme list | tr -s ' ' ' '
