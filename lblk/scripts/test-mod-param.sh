huge_test()
{
#for param in poll_queues submit_queues
for param in poll_queues
do 
	echo "###################################################"
	echo "$param:"
	for i in `seq 1 32`;
	do
		depth=`echo 2^${i}|bc`;
		echo "------------------------------------"
		echo "modprobe null_blk $param=${depth}" ;
		modprobe null_blk $param=${depth};
		dmesg -c ;
		sleep .25
		modprobe -r null_blk;
	done
done
}

small_test()
{
for param in hw_queue_depth max_sectors gb poll_queues submit_queues queue_mode
do 
	echo "###################################################"
	echo "$param:"
	for i in -2 -1 0 1 2 4 8 32 64;
	do
		echo "------------------------------------"
		echo "modprobe null_blk $param=${i}" ;
		modprobe null_blk $param=${i};
		dmesg -c ;
		modprobe -r null_blk;
	done
done

param=bs
echo "###################################################"
echo "$param:"
for i in -2 -1 0 1 2 4 8 32 64 512 1024 2048 4096;
do
	echo "------------------------------------"
	echo "modprobe null_blk $param=${i}" ;
	modprobe null_blk $param=${i};
	dmesg -c ;
	modprobe -r null_blk;
done
}

git checkout for-next
git log -1
./compile_nullb.sh
huge_test
small_test
git checkout nullb-mod-parm-v3 
git log -1
./compile_nullb.sh
huge_test
small_test

