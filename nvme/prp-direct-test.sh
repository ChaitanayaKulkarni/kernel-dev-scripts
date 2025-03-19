dmesg -c > /dev/null
for bs in 5 6 7 8;
do
	echo "-------------------------------------------------------"
	echo "WRITE"
	dd if=/dev/zero of=/dev/nvme0n1 count=1 bs=${bs}k oflag=direct
	dmesg -c
	echo "READ"
	dd if=/dev/nvme0n1 of=/dev/null count=1 bs=${bs}k iflag=direct
	dmesg -c
done
