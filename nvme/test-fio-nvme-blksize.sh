for i in 4 5 6 7 8 9 10 12 14 16 18 32 64 128 256 512;
do
	modprobe -r nvme
	modprobe nvme
	sleep 1
	dmesg -c > /dev/null
	printf "\------------------------blksize $i-------------------------------\n\n\n"
	echo "	fio fio/verify.fio --blocksize=${i}k --filename=/dev/nvme0n1 --ioengine=io_uring"
	fio fio/verify.fio --blocksize=${i}k --filename=/dev/nvme0n1 --ioengine=io_uring
	dmesg -c

#	echo "press enter to continue .... "
#	read next 
done 

