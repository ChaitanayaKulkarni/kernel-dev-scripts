

for bounce in 0 1
do 
	modprobe -r null_blk
	i=0
	echo "Module param bounce ${bounce}"
	modprobe null_blk nr_devices=0 bounce=${bounce}
	# Create dev 0 no bounce 
	NULLB_DIR=config/nullb/nullb${i}
	mkdir config/nullb/nullb${i}
	echo 1 > config/nullb/nullb${i}/memory_backed
	echo 512 > config/nullb/nullb${i}/blocksize 
	echo 2048 > config/nullb/nullb${i}/size 
	echo 1 > config/nullb/nullb${i}/power
	echo -n "$nullb${i} membacked : ";
	cat /sys/kernel/config/nullb/nullb${i}/memory_backed 
	echo -n "$nullb${i} bounce   : ";
	cat /sys/kernel/config/nullb/nullb${i}/bounce
	# Create dev 1 with bounce 
	i=1
	NULLB_DIR=config/nullb/nullb${i}
	mkdir config/nullb/nullb${i}
	echo 1 > config/nullb/nullb${i}/memory_backed
	echo 512 > config/nullb/nullb${i}/blocksize 
	echo 2048 > config/nullb/nullb${i}/size 
	echo 1 > config/nullb/nullb${i}/bounce
	echo 1 > config/nullb/nullb${i}/power
	echo -n "$nullb${i} membacked : ";
	cat /sys/kernel/config/nullb/nullb${i}/memory_backed 
	echo -n "$nullb${i} bounce   : ";
	cat /sys/kernel/config/nullb/nullb${i}/bounce

 	dd if=/dev/zero of=/dev/nullb0 bs=4096 count=1 oflag=direct
 	dd if=/dev/zero of=/dev/nullb0 bs= count=1 oflag=direct

	echo 0 > config/nullb/nullb0/power
	echo 0 > config/nullb/nullb1/power
	rmdir config/nullb/nullb*

	modprobe -r null_blk
	modprobe null_blk
	# should fail 
	blkdiscard -o 0 -l 1024 /dev/nullb0 
	modprobe -r null_blk
	modprobe null_blk discard=1
	# should pass
	blkdiscard -o 0 -l 1024 /dev/nullb0 
	modprobe -r null_blk
	echo "--------------------------"
done

modprobe -r null_blk
modprobe null_blk
blkdiscard -o 0 -l 1024 /dev/nullb0 
modprobe -r null_blk
modprobe null_blk discard=1
blkdiscard -o 0 -l 1024 /dev/nullb0 
modprobe -r null_blk
