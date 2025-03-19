#~/bin/bash

git log -1
./compile_nullb.sh
set +x
modprobe null_blk timeout=1,40,1,-1 rq_abort_limit=5
echo "##################"
echo "##################"
lsblk | grep nullb0
for ((i=0;i<10;i++))
do
	dd if=/dev/zero of=/dev/nullb0 oflag=direct bs=4k count=110000
	echo "##################"
	echo "##################"
	lsblk | grep nullb0
	if [ $? -eq 0 ]; then
		dmesg -c 
		continue
	fi
	dmesg -c 
	break
done
modprobe -r null_blk

modprobe null_blk timeout=1,40,1,-1 rq_abort_limit=5
echo "##################"
echo "##################"
lsblk | grep nullb0
for ((i=0;i<10;i++))
do
	fio fio/randread.fio --filename=/dev/nullb0
	echo "##################"
	echo "##################"
	lsblk | grep nullb0
	if [ $? -eq 0 ]; then
		dmesg -c 
		continue
	fi
	dmesg -c 
	break
done
lsblk
modprobe -r null_blk
set -x
