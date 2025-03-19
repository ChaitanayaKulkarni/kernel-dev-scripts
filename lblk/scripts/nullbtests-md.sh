#!/bin/bash -x


make_md()
{
mdadm -S /dev/md0
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/nullb${i}
  o 
  n 
  p
  1
    
  
  t
  8e
  p
  w
  q

EOF

sleep 1


mdadm --examine /dev/nullb0p1 /dev/nullb1p1
yes | mdadm --create  --force /dev/md0 --level=mirror --raid-devices=2 /dev/nullb0p1 /dev/nullb1p1
mdadm --detail /dev/md0
dmesg -c > /dev/null

}

#rmmod host/test.ko
lvremove /dev/nullbvg/nullblv
vgremove nullbvg
pvremove /dev/nullb0p1 /dev/nullb1p1

rmdir config/nullb/nullb0
rmdir config/nullb/nullb1

modprobe -r null_blk
modprobe null_blk nr_devices=0 verify=1

declare -a arr
for i in 0 1
do

	NULLB_DIR=config/nullb/nullb${i}
	mkdir config/nullb/nullb${i}

	tree config/nullb/nullb${i}

	sleep 1
	echo 1 > config/nullb/nullb${i}/memory_backed
	echo 512 > config/nullb/nullb${i}/blocksize 
	echo 10 > config/nullb/nullb${i}/size 
	echo 1 > config/nullb/nullb${i}/verify
	echo 1 > config/nullb/nullb${i}/power
	IDX=`cat config/nullb/nullb${i}/index`
	sleep 1
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/nullb${i}
  o 
  n 
  p
  1
    
  
  t
  8e
  p
  w
  q

EOF
        
	sleep 1
	partprobe 
	sleep 1
	pvcreate /dev/nullb${i}p1
	sleep 1
done

vgcreate nullbvg /dev/nullb0p1 /dev/nullb1p1
lvcreate -l 4 -n nullblv nullbvg # RAID 0 Linear 

sleep 1
dmesg -c
insmod host/test.ko nblk=16

#dd if=/dev/zero of=/dev/nullb${IDX} bs=512 count=10 oflag=direct

#dmesg -c
#echo 1 > /config/nullb/nullb0/power
#rmdir config/nullb/nullb0
