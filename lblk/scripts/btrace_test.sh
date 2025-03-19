
#WRITE
dd if=/dev/zero of=/dev/nullb0 bs=4k count=10 oflag=direct

#MERGE
dd if=/dev/zero of=/dev/nullb0 bs=4k count=10

#READ
dd if=/dev/nullb0 of=/dev/null bs=4k count=10
