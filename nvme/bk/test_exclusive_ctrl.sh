PT_DEV=/dev/nvme0
PT_CTRL=nvme0

set -x
mkdir /sys/kernel/config/nvmet/passthru/${PT_CTRL}
sleep 1

echo -n "${PT_DEV}" > /sys/kernel/config/nvmet/passthru/${PT_CTRL}/attr_ctrl_path 
sleep 1
echo 1 > /sys/kernel/config/nvmet/passthru/${PT_CTRL}/attr_enable
