
for i in 1024 512 256 128 #64 32 16 8 4;
do

	printf "\------------------------blksize $i-------------------------------\n\n\n"

	fio --group_reporting=1 --name=verify --rw=randwrite --allow_file_create=0 \
	--direct=1 --ioengine=io_uring --bs="${i}k" --iodepth=16 --verify=crc32c \
	--verify_state_save=0 --size=100m --filename=/dev/nvme0n1 \
	--norandommap --randrepeat=0  #--mem_align=120 
done


