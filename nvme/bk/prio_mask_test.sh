#!/bin/bash

read_op()
{
set -x 
for i in 1 2 3 4 #5 6 7 8 9 A B C D E F
do
	/blktrace/blktrace -P -a read -X ${i} -d /dev/nullb0 -o - | blktrace/blkparse -p -i - >> /tmp/op 2>&1 &
	sleep 2
	for prio in `seq 0 3`; do echo "$prio"; ionice -c ${prio} ./read.sh ; done
	killall blktrace
done
}

write_op()
{
for i in 1 2 3 4 #5 6 7 8 9 A B C D E F
do
	/blktrace/blktrace -P -a write -X ${i} -d /dev/nullb0 -o - | blktrace/blkparse -p -i - >> /tmp/op 2>&1 &
	sleep 2
	for prio in `seq 0 3`; do echo "$prio"; ionice -c ${prio} ./write.sh ; done
	killall blktrace
done
}

write_zeroes_op()
{
for i in 1 2 3 4 #5 6 7 8 9 A B C D E F
do
	set +x
	./blktrace/blktrace -P -E -y write_zeroes -X ${i} -d /dev/nullb0 -o - | blktrace/blkparse -P -E -i - >> /tmp/op &
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

write_zeroes_op
