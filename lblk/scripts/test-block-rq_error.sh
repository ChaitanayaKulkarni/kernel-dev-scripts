set -x
cd tracing

modprobe -r null_blk
rm -fr /dev/nullb0
modprobe null_blk
sleep 1

set +x 
echo "###############################################################"
echo "# Disable block_rq_[complete|error] tracepoints"
echo "#"
set -x
echo 0 > events/block/block_rq_complete/enable 
echo 0 > events/block/block_rq_error/enable 

cat events/block/block_rq_complete/enable 
cat events/block/block_rq_error/enable 
        
set +x 
echo "###############################################################"
echo "# Enable block_rq_complete() tracepoint and generate write error"
echo "#"
set -x
echo 1 > events/block/block_rq_complete/enable 
cat events/block/block_rq_complete/enable 
dd if=/dev/zero of=/dev/nullb0 bs=64k count=10 oflag=direct seek=1024
cat trace
echo "" > trace

set +x 
echo "###############################################################"
echo "# Enable block_rq_[complete|error]() tracepoint and "
echo "# generate write error "
echo "#"
set -x
echo 1 > events/block/block_rq_error/enable 
cat events/block/block_rq_error/enable 
dd if=/dev/zero of=/dev/nullb0 bs=64k count=10 oflag=direct seek=10240
cat trace
echo "" > trace

set +x 
echo "###############################################################"
echo "# Disable block_rq_complete() and keep block_rq_error()"
echo "# tracepoint enabled and generate write error "
echo "#"
set -x
echo 0 > events/block/block_rq_complete/enable 
cat events/block/block_rq_complete/enable 

dd if=/dev/zero of=/dev/nullb0 bs=64k count=10 oflag=direct seek=10240
cat trace
echo "" > trace

modprobe -r null_blk
set +x
