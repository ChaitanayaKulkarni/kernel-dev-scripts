set -x 

FILE="/mnt/backend/nvme1n1"
SS=testnqn
SSPATH=/sys/kernel/config/nvmet/subsystems/${SS}/
PORTS=/sys/kernel/config/nvmet/ports

load_modules()
{
	dmesg -c > /dev/null
	modprobe nvme
	modprobe nvme-fabrics
	modprobe nvmet
	modprobe nvme-loop
	sleep 3 
}

make_nvme()
{
	mkfs.xfs -f /dev/nvme0n1
	mount /dev/nvme0n1 /mnt/backend/nvme0n1
	sleep 1
	mount | column -t | grep nvme
}

make_nullb()
{
	./compile_nullb.sh
	./compile_nullb.sh
	modprobe null_blk nr_devices=0
	sleep 1

	mkdir config/nullb/nullb0
	tree config/nullb/nullb0
	echo 1 > config/nullb/nullb0/memory_backed
	echo 512 > config/nullb/nullb0/blocksize 
	# 20 GB
	echo 20480 > config/nullb/nullb0/size 
	echo 1 > config/nullb/nullb0/power
	sleep 2
	IDX=`cat config/nullb/nullb0/index`
	lsblk | grep null${IDX}
	sleep 1

	mkfs.xfs -f /dev/nullb0
	mount /dev/nullb0 /mnt/backend/
	sleep 1
	mount | column -t | grep nvme

	# 10 GB
	dd if=/dev/zero of=${FILE} count=2621440 bs=4096
}

mount_fs()
{
	make_nullb
	file ${FILE} 
}

make_target()
{
	tree /sys/kernel/config
	mkdir ${SSPATH}

	for i in 1
	do
		mkdir ${SSPATH}/namespaces/${i}
		echo -n ${FILE} > ${SSPATH}/namespaces/${i}/device_path
#echo 1 > ${SSPATH}/namespaces/${i}/buffered_io
		cat ${SSPATH}/namespaces/${i}/device_path
		cat ${SSPATH}/namespaces/${i}/buffered_io
		echo 1 > ${SSPATH}/namespaces/${i}/enable 
	done

	mkdir ${PORTS}/1/
	echo -n "loop" > ${PORTS}/1/addr_trtype 
	echo -n 1 > ${SSPATH}/attr_allow_any_host
	ln -s ${SSPATH} ${PORTS}/1/subsystems/
	sleep 1
}

connect()
{
	echo  "transport=loop,nqn=${SS}" > /dev/nvme-fabrics
	sleep 1
}

main()
{
	load_modules
	mount_fs
	make_target
	connect

	dmesg -c
}

main
