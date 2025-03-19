set -x 

#FILE="/dev/nvme0n1"
FILE="/dev/nullb0"

modprobe -r test_verify
modprobe -r null_blk
modprobe null_blk verify=$1 gb=50
modprobe nvme
modprobe nvme-fabrics
modprobe nvmet
dmesg -c  /dev/null
sleep 3 

tree /sys/kernel/config

mkdir /sys/kernel/config/nvmet/subsystems/fs

for i in 1
do
	mkdir /sys/kernel/config/nvmet/subsystems/fs/namespaces/${i}
	echo -n ${FILE} > /sys/kernel/config/nvmet/subsystems/fs/namespaces/${i}/device_path
	cat /sys/kernel/config/nvmet/subsystems/fs/namespaces/${i}/device_path
	echo 1 > /sys/kernel/config/nvmet/subsystems/fs/namespaces/${i}/enable 
done

mkdir /sys/kernel/config/nvmet/ports/1/
echo -n "loop" > /sys/kernel/config/nvmet/ports/1/addr_trtype 
echo -n 1 > /sys/kernel/config/nvmet/subsystems/fs/attr_allow_any_host
ln -s /sys/kernel/config/nvmet/subsystems/fs /sys/kernel/config/nvmet/ports/1/subsystems/
sleep 1
echo  "transport=loop,nqn=fs" > /dev/nvme-fabrics
sleep 1

mount | column -t | grep nvme
dmesg -c
