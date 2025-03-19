
./compile_nvme.sh

echo "enabling genctrrrrr "
modprobe -r nvme
modprobe -r nvme-core 
modprobe nvme-core use_genctr=1 
modprobe nvme
sleep 3
dd if=/dev/zero of=/dev/nvme0n1 bs=4k count=1 oflag=direct
modprobe -r nvme
modprobe -r nvme-core 
sleep 3
dmesg -c 


echo "disabling genctrrrrr "
modprobe nvme-core use_genctr=0
modprobe nvme
sleep 3
dd if=/dev/zero of=/dev/nvme0n1 bs=4k count=1 oflag=direct
dmesg -c 
sleep 3
