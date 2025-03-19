set -x 
time umount /mnt/brd
time modprobe -r brd
modprobe brd rd_size=$((40*1024*1024)) rd_nr=1 
mkfs.xfs /dev/ram0 
mount /dev/ram0 /mnt/brd
dd if=/dev/zero of=/mnt/brd/file1 bs=4k oflag=direct                                          
free -m
time umount /mnt/brd
free -m
time modprobe -r brd
set +x
