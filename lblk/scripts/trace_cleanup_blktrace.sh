#!/bin/bash

#bio_queue
#bio_bounce
#bio_backmerge
#bio_getrq
#rq_insert
#rq_issue
#rq_complete
#bio_complate
        
TRACE="/sys/kernel/debug/tracing"

config_tracing()
{
	echo 0 >  $TRACE/trace
	echo 0 > $TRACE/tracing_on

	blktrace -a write -d /dev/nullb0 -o - | blkparse -i - >> /tmp/op 2>&1 &
	sleep 2
}

test_sched()
{
	modprobe -r null_blk
	modprobe null_blk bounce_pfn=32

	for i in kyber bfq mq-deadline none
	do
		config_tracing
		echo "####################     $i     #####################" >> /tmp/op
		echo "####################     $i     #####################"
		echo ${i} > /sys/block/nullb0/queue/scheduler
		cat /sys/block/nullb0/queue/scheduler
		dd if=/dev/zero of=/dev/nullb0 bs=4k count=5
		sleep 2
		killall blktrace
		sleep 2
	done
	modprobe -r null_blk
}

test_split()
{
	modprobe -r null_blk
	modprobe null_blk discard=1

	config_tracing

	echo "####################     split     #####################" >> /tmp/op 
	echo 2048 > /sys/block/nullb0/queue/discard_max_bytes 
	blkdiscard -o 0 -l 40960 /dev/nullb0
	sleep 2
	killall blktrace
	sleep 2
	modprobe -r null_blk
}

test_requeue()
{
	modprobe -r null_blk
	modprobe null_blk requeue="1,50,1,200"

	config_tracing
	echo "####################     requeue     #####################" >> /tmp/op 
	echo 1 > ${TRACE}/options/blk_cgroup

	echo mq-deadline > /sys/block/nullb0/queue/scheduler
	dd if=/dev/zero of=/dev/nullb0 bs=4k count=10 oflag=direct
	killall blktrace
	sleep 2
	modprobe -r null_blk
}

test_cgroup()
{
	modprobe -r null_blk
	modprobe null_blk
	BLK_IO_CG=/sys/fs/cgroup/blkio/g1

	echo "####################     cgroup     #####################" >> /tmp/op 

	config_tracing
	echo 1 > ${TRACE}/options/blk_cgroup

	mkdir -p ${BLK_IO_CG} 
	echo "252:0 1048576" > ${BLK_IO_CG}/blkio.throttle.read_bps_device
	echo "252:0 1048576" > ${BLK_IO_CG}/blkio.throttle.write_bps_device
	echo $$ > ${BLK_IO_CG}/cgroup.procs
	sleep 1
	dd if=/dev/zero of=/dev/nullb0 bs=4k count=10 oflag=direct
	dd if=/dev/zero of=/dev/nullb0 bs=4k count=10
	sleep 1
	killall blktrace
	sleep 2
	modprobe -r null_blk
}

git log --oneline -7
uname -r
rm -fr /tmp/op
test_sched
test_split
test_requeue
test_cgroup
cat /tmp/op
