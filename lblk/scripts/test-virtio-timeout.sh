
set -x 
modprobe -r virtio_blk
insmod drivers/block/virtio_blk.ko
sleep 1
lsblk
ls -lrth /dev/vda
dmesg -c

blkdiscard -z -o 0 -l 40960 /dev/vda
sleep 1
lsblk
ls -lrth /dev/vda
dmesg -c

blkdiscard -z -o 0 -l 40960 /dev/vda
sleep 1
lsblk
ls -lrth /dev/vda
dmesg -c

modprobe -r virtio_blk
