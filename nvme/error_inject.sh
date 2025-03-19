
ctrl_dev=nvme1
do_fault_inject()
{
#./compile_nvme.sh
	./bdev.sh 1
	nvme list | grep -v "\-\-\-" | tr -s ' ' ' ' 

	echo 0x286 > /sys/kernel/debug/${ctrl_dev}/fault_inject/status
	echo 1000 > /sys/kernel/debug/${ctrl_dev}/fault_inject/times
	echo 100 > /sys/kernel/debug/${ctrl_dev}/fault_inject/probability

	nvme admin-passthru /dev/${ctrl_dev} --opcode=06 --data-len=4096 --cdw10=1 -r

	nvme list | grep -v "\-\-\-" | tr -s ' ' ' ' 
	dmesg -c 
	./delete.sh
}

dmesg -c > /tmp/dmesg

do_fault_inject
#cat ./0001-nvme-core-mark-internal-passthru-req-REQ_QUIET.patch
#git am ./0001-nvme-core-mark-internal-passthru-req-REQ_QUIET.patch 
#read next
#git log -1 
#do_fault_inject
#git reset HEAD~1 --hard
