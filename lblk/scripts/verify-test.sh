

echo "nvme-pcie"
modprobe -r nvme
dmesg -c > /dev/null
modprobe nvme
blkverify -o 4096 -l 409600 /dev/nvme0n1
dmesg -c
modprobe -r nvme
read next

echo "null_blk verify=0"
modprobe -r null_blk
modprobe null_blk verify=0
dmesg -c > /dev/null
blkverify -o 4096 -l 409600 /dev/nullb0
dmesg -c
modprobe -r null_blk
read next

echo "null_blk verify=1"
modprobe -r null_blk
modprobe null_blk verify=1
dmesg -c > /dev/null
blkverify -o 4096 -l 409600 /dev/nullb0
dmesg -c
modprobe -r null_blk
read next

echo "bdev-ns null_blk verify=0"
./bdev.sh 1 0
blkverify -o 4096 -l 409600 /dev/nvme1n1
./delete.sh 1
dmesg -c
read next

echo "bdev-ns null_blk verify=1"
./bdev.sh 1 1
blkverify -o 4096 -l 409600 /dev/nvme1n1
./delete.sh 1
dmesg -c 
read next

echo "scsi debug"
insmod drivers/scsi/scsi_debug.ko  dev_size_mb=4096
blkverify -o 4096 -l 409600 /dev/sdc
modprobe -r scsi_debug
dmesg -c 
read next
