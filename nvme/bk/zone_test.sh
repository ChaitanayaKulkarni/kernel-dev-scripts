blkzone reset $1
blkzone report $1 | cut -c 80-95


echo " Press enter to open "
read next

blkzone open $1
blkzone report $1 | cut -c 80-95
dmesg -c

echo " Press enter to close"
read next

blkzone close $1
blkzone report $1 | cut -c 80-95
dmesg -c

echo " Press enter to finish"
read next

blkzone finish $1
blkzone report $1 | cut -c 80-95
dmesg -c

