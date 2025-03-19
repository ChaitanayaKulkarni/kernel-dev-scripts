rmmod blk_lib_test
rmmod null_blk
./compile_nullb.sh
./compile_nvme.sh
modprobe null_blk gb=2
blkzone report /dev/nullb0
insmod host/blk_lib_test.ko
dmesg -c

rmmod blk_lib_test
rmmod null_blk
./compile_nullb.sh
./compile_nvme.sh
modprobe null_blk gb=2 zoned=1 
blkzone report /dev/nullb0
insmod host/blk_lib_test.ko
dmesg -c

