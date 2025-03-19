
echo 1 > /sys/class/nvme/nvme0/passthru_admin_err_logging 
nvme telemetry-log -o /tmp/test /dev/nvme0  
nvme write-zeroes -n 1 -s 0x200000 -c 10 /dev/nvme0
dmesg -c 


