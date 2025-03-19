set -x

check_memleak()
{
	for ((i=0;i<5; i++)); do
		echo scan > /sys/kernel/debug/kmemleak
		cat /sys/kernel/debug/kmemleak
		cat /sys/kernel/debug/kmemleak | grep backtrace
		if [ $? -eq 0 ]; then
			echo clear > /sys/kernel/debug/kmemleak
			break
		fi
		sleep 3
	done
}

modprobe -r nvme-loop
modprobe -r nvmet
modprobe -r nvme-fabrics
modprobe -r nvme
modprobe -r nvme-core
modprobe -r nvme-common

echo "------------------------------------"
insmod drivers/nvme/common/nvme-common.ko 
check_memleak

echo "------------------------------------"
insmod host/nvme-core.ko 
check_memleak

echo "------------------------------------"
insmod host/nvme.ko
check_memleak

echo "------------------------------------"
insmod drivers/nvme/host/nvme-fabrics.ko 
check_memleak

#<<COMM
echo clear > /sys/kernel/debug/kmemleak
echo "------------------------------------"
insmod drivers/nvme/target/nvmet.ko 
check_memleak

echo "------------------------------------"
insmod drivers/nvme/target/nvme-loop.ko 
check_memleak

modprobe -r nvme-loop
check_memleak
modprobe -r nvmet
check_memleak
#COMM

modprobe -r nvme-fabrics
check_memleak
modprobe -r nvme
check_memleak
modprobe -r nvme-core
check_memleak
modprobe -r nvme-common
check_memleak

lsmod | grep nvme

