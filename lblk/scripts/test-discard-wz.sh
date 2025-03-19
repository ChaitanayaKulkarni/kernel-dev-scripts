
zone_sz_mb=128
zone_sz_bytes=`echo "${zone_sz_mb}*1024*1024" | bc`

test_discard()
{
	echo "###################################################"
	git diff block drivers/block/null_blk
	modprobe -r null_blk
	modprobe null_blk discard=1
	blkdiscard -o 0 -l 40960 /dev/nullb0 
	blkdiscard -o 1024 -l 10240 /dev/nullb0 
	dmesg  -c 
}

test_write_zeroes_offload()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk write_zeroes=1
	blkdiscard -z -o 0 -l 40960 /dev/nullb0 
	blkdiscard -z -o 1024 -l 10240 /dev/nullb0 
	dmesg  -c 
}

test_write_zeroes_emulated()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk
	blkdiscard -z -o 0 -l 40960 /dev/nullb0 
	blkdiscard -z -o 1024 -l 10240 /dev/nullb0 
	dmesg  -c 
}

test_zone_open()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk zoned=1 gb=1 zone_size=${zone_sz_mb}

	dd if=/dev/zero of=/dev/nullb0 bs=4k oflag=direct #count=10
	blkzone report /dev/nullb0 | cut -b 1-82
	for i in 7 6 5 4 3 2 1 0
	do
		offset=`echo "(${zone_sz_bytes}*${i})/512" | bc`;
		blkzone open -o ${offset} -l 262144 /dev/nullb0
		dmesg -c
		echo "-----------------------------------------"
		blkzone report /dev/nullb0 | cut -b 1-82
	done
}

test_zone_close()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk zoned=1 gb=1 zone_size=${zone_sz_mb}

	blkzone open /dev/nullb0
	blkzone report /dev/nullb0 | cut -b 1-82
	for i in 7 6 5 4 3 2 1 0
	do
		offset=`echo "(${zone_sz_bytes}*${i})/512" | bc`;
		blkzone close -o ${offset} -l 262144 /dev/nullb0
		dmesg -c
		echo "-----------------------------------------"
		blkzone report /dev/nullb0 | cut -b 1-82
	done
}

test_zone_finish()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk zoned=1 gb=1 zone_size=${zone_sz_mb}

	blkzone open /dev/nullb0
	blkzone report /dev/nullb0 | cut -b 1-82
	for i in 7 6 5 4 3 2 1 0
	do
		offset=`echo "(${zone_sz_bytes}*${i})/512" | bc`;
		blkzone finish -o ${offset} -l 262144 /dev/nullb0
		dmesg -c
		echo "-----------------------------------------"
		blkzone report /dev/nullb0 | cut -b 1-82
	done
}

test_zone_reset()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk zoned=1 gb=1 zone_size=${zone_sz_mb}

	dd if=/dev/zero of=/dev/nullb0 bs=4k oflag=direct #count=10
	blkzone report /dev/nullb0 | cut -b 1-82
	for i in 7 6 5 4 3 2 1 0
	do
		offset=`echo "(${zone_sz_bytes}*${i})/512" | bc`;
		blkzone reset -o ${offset} -l 262144 /dev/nullb0
		echo "-----------------------------------------"
		blkzone report /dev/nullb0 | cut -b 1-82
	done
	dmesg -c
}

test_zone_open()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk zoned=1 gb=1 zone_size=${zone_sz_mb}

	dd if=/dev/zero of=/dev/nullb0 bs=4k oflag=direct #count=10
	blkzone report /dev/nullb0 | cut -b 1-82
	for i in 7 6 5 4 3 2 1 0
	do
		offset=`echo "(${zone_sz_bytes}*${i})/512" | bc`;
		blkzone reset -o ${offset} -l 262144 /dev/nullb0
		echo "-----------------------------------------"
		blkzone report /dev/nullb0 | cut -b 1-82
	done
	dmesg -c
}

test_zone_reset_all_offload()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk zoned=1 gb=1 zone_size=${zone_sz_mb}
	dd if=/dev/zero of=/dev/nullb0 bs=4k oflag=direct #count=10
	blkzone report /dev/nullb0 | cut -b 1-82
	blkzone reset /dev/nullb0
	dmesg -c 
	blkzone report /dev/nullb0 | cut -b 1-82
	dmesg -c 
}

test_zone_reset_all_emulated()
{
	echo "###################################################"
	modprobe -r null_blk
	modprobe null_blk zoned=1 gb=1 zone_size=${zone_sz_mb} zone_reset_all=0
	dd if=/dev/zero of=/dev/nullb0 bs=4k oflag=direct #count=10
	blkzone report /dev/nullb0 | cut -b 1-82
	blkzone reset /dev/nullb0
	dmesg -c 
	blkzone report /dev/nullb0 | cut -b 1-82
	modprobe -r null_blk
	rm -fr /dev/nullb0
	dmesg -c 
	modprobe -r null_blk
}

set -x 
test_discard
#read next
test_write_zeroes_offload
#read next
test_write_zeroes_emulated
#read next
test_zone_open
#read next
test_zone_close
#read next
test_zone_finish
#read next
test_zone_reset_all_offload
##read next
test_zone_reset_all_emulated
#read next
