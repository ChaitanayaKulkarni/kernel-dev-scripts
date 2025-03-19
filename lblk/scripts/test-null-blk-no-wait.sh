set -x 

test_non_configfs()
{

modprobe null_blk nowait=0 queue_mode=0
dmesg -c 
for i in 1 2 3; do
	fio fio/randread.fio --filename=/dev/nullb0 --output=qmode-0-nowait-0-fio-$i.log
done
modprobe -r null_blk

modprobe null_blk nowait=1 queue_mode=0
dmesg -c 
for i in 1 2 3; do
	fio fio/randread.fio --filename=/dev/nullb0 --output=qmode-0-nowait-1-fio-$i.log
done
modprobe -r null_blk

modprobe null_blk nowait=0 queue_mode=2
dmesg -c 
for i in 1 2 3; do
	fio fio/randread.fio --filename=/dev/nullb0 --output=qmode-2-nowait-0-fio-$i.log
done
modprobe -r null_blk

modprobe null_blk nowait=1 queue_mode=2
dmesg -c 
for i in 1 2 3; do
	fio fio/randread.fio --filename=/dev/nullb0 --output=qmode-2-nowait-1-fio-$i.log
done
modprobe -r null_blk
}

test_configfs()
{
	qmode=$1
	nowait=$2

	modprobe null_blk nr_devices=0
	NULLB_DIR=config/nullb/nullb0
	mkdir config/nullb/nullb0

	echo 1 > config/nullb/nullb0/memory_backed
	echo 4096 > config/nullb/nullb0/blocksize 
	echo 20480 > config/nullb/nullb0/size
	echo $qmode > config/nullb/nullb0/queue_mode
	echo $nowait > config/nullb/nullb0/nowait

	echo 1 > config/nullb/nullb0/power
	if [ $? -ne 0 ]; then
		echo "error null_blk_poer_on"
	fi

	sleep .50
	for i in 1 2 3; do
		fio fio/randread.fio --filename=/dev/nullb0 \
		--output=configfs-qmode-$qmode-nowait-$nowait-fio-$i.log
	done
	rmdir config/nullb/nullb*
	modprobe -r null_blk
}

modprobe -r null_blk
./compile_nullb.sh

test_non_configfs
test_configfs 0 0
test_configfs 0 1
#test_configfs 1 0
#test_configfs 1 1
test_configfs 2 0
test_configfs 2 1
