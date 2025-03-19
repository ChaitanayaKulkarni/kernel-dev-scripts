modprobe nvmet
sleep 1
set -x 
echo 0 > tracing/tracing_on
echo 'nvmet:nvmet_req_init' > tracing/set_event
#echo 'nvme:nvme_setup_cmd' >> tracing/set_event
echo 1 > tracing/events/nvmet/nvmet_req_init/enable
echo 1 > tracing/tracing_on
cat tracing/trace_pipe
echo 0 > tracing/tracing_on
set +x 
