#!/bin/bash

set -x 
nvme disconnect -n pt-nqn
rm -fr /sys/kernel/config/nvmet/ports/1/subsystems/pt-nqn
rmdir /sys/kernel/config/nvmet/ports/1
echo 0 > /sys/kernel/config/nvmet/subsystems/pt-nqn/passthru/enable
rmdir /sys/kernel/config/nvmet/subsystems/pt-nqn
sleep 1
modprobe -r nvme_loop
modprobe -r nvme_fabrics
modprobe -r nvmet
modprobe -r nvme
modprobe -r nvme_core
