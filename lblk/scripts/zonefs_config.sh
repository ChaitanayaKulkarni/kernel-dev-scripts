
NN=1

modprobe -r null_blk
./compile_nullb.sh
modprobe null_blk nr_devices=0

modprobe -r zonefs
makej M=fs/zonefs/
insmod fs/zonefs/zonefs.ko

echo loading devices
for i in 0
do
	NULLB_DIR=config/nullb/nullb${i}
	mkdir config/nullb/nullb${i}

	echo 1 > config/nullb/nullb${i}/memory_backed
	echo 512 > config/nullb/nullb${i}/blocksize 
	echo 1024 > config/nullb/nullb${i}/size 
	echo 1 > config/nullb/nullb${i}/zoned
	echo 128 > config/nullb/nullb${i}/zone_size
	echo 1 > config/nullb/nullb${i}/power
	IDX=`cat config/nullb/nullb${i}/index`
	echo -n " $i "
	sleep .50
done

blkzone reset /dev/nullb0
blkzone report /dev/nullb0
mkfs.zonefs -o uid=1000,gid=1000 /dev/nullb0

mount /dev/nullb0 /mnt/nullb0
tree /mnt/nullb0
