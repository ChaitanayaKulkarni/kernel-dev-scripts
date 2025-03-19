modprobe nvme
modprobe nvmet
sleep 1

set -x

echo 1 > /sys/kernel/debug/tracing/events/nvme/enable 
echo 1 > /sys/kernel/debug/tracing/events/nvmet/enable 
cat /sys/kernel/debug/tracing/trace_pipe 
set +x

#while inotifywait -e modify /mnt/backend/nvme1n1
#do
#	echo 1 > /sys/kernel/config/nvmet/subsystems/fs/namespaces/1/resize_check
#done

