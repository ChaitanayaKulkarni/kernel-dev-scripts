#!/bin/bash -x

read_op()
{
set -x 
for i in 1 2 3 4 #5 6 7 8 9 A B C D E F
do
	blktrace/blktrace -P -a read -X ${i} -d /dev/nullb0 -o - | \
	blktrace/blkparse -p -i - >> /tmp/op 2>&1 &
	sleep 2
	for prio in `seq 0 3`; do echo "$prio"; ionice -c ${prio} ./read.sh ; done
	killall blktrace
done
}

write_op()
{
for i in 1 2 3 4 #5 6 7 8 9 A B C D E F
do
	blktrace/blktrace -P -a write -X ${i} -d /dev/nullb0 -o - | \
	blktrace/blkparse -p -i - >> /tmp/op 2>&1 &
	sleep 2
	for prio in `seq 0 3`; do echo "$prio"; ionice -c ${prio} ./write.sh ; done
	killall blktrace
done
}

write_zeroes_op()
{
for i in 1 2 3 4 5 6 7 8 9 A B C D E F
do
	set +x
	./blktrace/blktrace -P -E -y write_zeroes -X ${i} -d /dev/nullb0 -o - | \
	blktrace/blkparse -P -E -i - >> /tmp/op &
	sleep 3
	for prio in `seq 0 3`
	do
		echo "$prio"; ionice -c ${prio} blkdiscard -z -o 0 -l 4096 /dev/nullb0;
	done
	killall blktrace
	killall blktrace
	killall blktrace
	sleep 10
	set -x
done
}

zone_append()
{
for i in 1 2 3 4 5 6 7 8 9 A B C D E F
do
	set +x
	./blktrace/blktrace -P -E -y zone_append -X ${i} -d /dev/nullb0 -o - | \
	blktrace/blkparse -P -E -i - >> /tmp/op &
	sleep 5
	for prio in `seq 0 3`
	do
		echo "---------------------------------------------" >> /tmp/op
		echo "Using Priority mask 0x${i}" >> /tmp/op
		echo "---------------------------------------------" >> /tmp/op
		truncate -s 0 /mnt/nullb0/seq/0

		ionice -c ${prio} dd if=/dev/zero of=/mnt/nullb0/seq/0 bs=4k count=5 \
					oflag=direct oflag=sync
	done
	killall blktrace
	killall blktrace
	killall blktrace
	sleep 10
	set -x
done
}

> /tmp/op
zone_append
#write_zeroes_op
