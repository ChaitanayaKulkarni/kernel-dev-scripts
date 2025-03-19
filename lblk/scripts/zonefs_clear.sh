umount /mnt/nullb0
for i in config/nullb/nullb*; do rmdir ${i}; done
modprobe -r null_blk
