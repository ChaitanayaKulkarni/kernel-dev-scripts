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
	echo blk > $TRACE/current_tracer
	echo 1 > $TRACE/events/block/enable
	echo $1 > ${TRACE}/options/blk_cgroup
	echo 1 > $TRACE/tracing_on
}

__test_sched()
{
	config_tracing 0

	for i in kyber bfq mq-deadline none
	do
		echo ${i} > /sys/block/nullb0/queue/scheduler
		cat /sys/block/nullb0/queue/scheduler
		dd if=/dev/zero of=/dev/nullb0 bs=4k count=5
		echo "####################     $i     #####################"
		cat $TRACE/trace | grep 252,0 | grep W  | tr -s ' ' ' ' | cut -f 1-10 -d ':'
		echo 0 > $TRACE/trace
	done
}

test_sched()
{
	modprobe -r null_blk
	modprobe null_blk bounce_pfn=32
	__test_sched
	modprobe -r null_blk

	#test attempt_merge tracepoint 
	modprobe null_blk
	dd if=/dev/zero of=/dev/nullb0 bs=4k count=1000000
	modprobe -r null_blk

}

test_split()
{
	modprobe -r null_blk
	modprobe null_blk discard=1

	config_tracing 0

	dd if=/dev/zero of=/dev/nullb0 bs=4k count=10 oflag=direct
	echo 2048 > /sys/block/nullb0/queue/discard_max_bytes 
	blkdiscard -o 0 -l 40960 /dev/nullb0
	cat $TRACE/trace | grep 252,0 | grep D
	echo 0 > $TRACE/trace
	sleep 2
}

test_requeue()
{
	modprobe -r null_blk
	modprobe null_blk requeue="1,50,1,10"

	config_tracing 0
	echo mq-deadline > /sys/block/nullb0/queue/scheduler
	cat $TRACE/trace | grep 252,0 | grep block_rq_requeue
	echo 0 > $TRACE/trace
	echo 0 > $TRACE/tracing_on
	modprobe -r null_blk
}

test_sched
test_split
test_requeue
