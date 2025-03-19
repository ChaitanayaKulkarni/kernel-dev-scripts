#!/bin/bash

losetup -D

for i in `seq 4`
do
	truncate -s 2G /tmp/loop${i}.img
	losetup /dev/loop${i} /tmp/loop${i}.img 
done
losetup -a

echo -e '0 1961317 linear /dev/loop0 0'\\n'1961317 1961317 linear /dev/loop1 0'\\n'3922634 1961317 linear /dev/loop2 0'\\n'5883951 1961317 linear /dev/loop3 0' | dmsetup create test-linear


