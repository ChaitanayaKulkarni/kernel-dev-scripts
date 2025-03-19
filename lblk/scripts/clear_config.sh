#!/bin/bash

set -x 
nvme disconnect -n nvme0
sleep 2
rm -fr /sys/kernel/config/nvmet/ports/1/subsystems/nvme0
sleep 2
rmdir /sys/kernel/config/nvmet/ports/1
sleep 2
rmdir /sys/kernel/config/nvmet/passthru/nvme0
sleep 2
modprobe -r nvme_loop
modprobe -r nvme_fabrics
modprobe -r nvmet
modprobe -r nvme
modprobe -r nvme_core
