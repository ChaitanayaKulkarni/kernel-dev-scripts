setup()
{
	echo "[RANDWRITE]"		>  /tmp/randwrite.fio
	echo "direct=1"			>> /tmp/randwrite.fio
	echo "rw=randwrite"		>> /tmp/randwrite.fio
	echo "norandommap"		>> /tmp/randwrite.fio
	echo "randrepeat=0"		>> /tmp/randwrite.fio
	echo "runtime=1m"		>> /tmp/randwrite.fio
	echo "time_based"		>> /tmp/randwrite.fio
	echo "iodepth=2"		>> /tmp/randwrite.fio
	echo "numjobs=48"		>> /tmp/randwrite.fio
	echo "bs=4k"			>> /tmp/randwrite.fio
	echo "overwrite=0"		>> /tmp/randwrite.fio
	echo "allow_file_create=0"	>> /tmp/randwrite.fio
	echo "group_reporting"		>> /tmp/randwrite.fio
	echo ""				>> /tmp/randwrite.fio


	./compile_nvme.sh
	modprobe -r nvme

	echo "--------------------------------------------"
	echo "modprobe nvme nvme_io_timeout=5"

	set -x
	lsmod | grep nvme
	modprobe nvme nvme_io_timeout=5
	set +x
	echo "--------------------------------------------"
	sleep 1

	if [ $? -ne 0 ] || [ ! -b /dev/nvme0n1 ]; then
		echo "failed to load nvme module"
		exit 1
	fi

	set -x
	lsblk
	ls -lrth /dev/nvme0n1

	cat /sys/block/nvme0n1/io-timeout-fail
	echo 1 > /sys/block/nvme0n1/io-timeout-fail
	cat /sys/block/nvme0n1/io-timeout-fail

	read next

	echo  99 > /sys/kernel/debug/fail_io_timeout/probability
	echo  10 > /sys/kernel/debug/fail_io_timeout/interval
	echo  -1 > /sys/kernel/debug/fail_io_timeout/times
	echo   0 > /sys/kernel/debug/fail_io_timeout/space
	echo   1 > /sys/kernel/debug/fail_io_timeout/verbose
	read next

	set +x
	dmesg -c
}

teardown()
{
	modprobe -r virtio_blk
}

main()
{
	setup

	set -x 
	fio /tmp/randwrite.fio --filename=/dev/nvme0n1 --ioengine=libaio
	set +x
	echo "--------------------------------------------"
	echo "device should be gone from lablk"
	set -x 
	ls -lrth /dev/nvme0n1
	lsblk

	teardown
}

main
