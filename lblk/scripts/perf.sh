set -x
echo 1 > tracing/events/block/block_rq_complete/enable
cat tracing/events/block/block_rq_complete/enable
for i in 1 2 3 4 5 6 7 8 9 10; do fio fio/randread.fio --filename=/dev/nullb0; done 

echo 0 > tracing/events/block/block_rq_complete/enable
cat tracing/events/block/block_rq_complete/enable
for i in 1 2 3 4 5 6 7 8 9 10; do fio fio/randread.fio --filename=/dev/nullb0; done 
