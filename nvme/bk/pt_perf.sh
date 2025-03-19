#!/bin/bash

perf_run()
{
	git log -1
	./compile_nvme.sh
	./bdev.sh 32 testnqn
	./passthru_config.sh /dev/nvme1
	sleep 1

	for nsid in `seq 1 32`; do
		while [ ! -b /dev/nvme2n${nsid} ]; do
			echo waiting /dev/nvme1n${nsid}
			sleep 1;
		done
	done 
	# fio fio/randread.fio --filename=/dev/nvme1n1 --output=$1$i.fio.log
	fio fio/multijob-32.fio #--output=$1-$i.fio.log

	./passthru_clear.sh
	./delete.sh 32 testnqn
}

#git co nvme-5.9-rc
#perf_run nvme-alloc-default 

#git co nvmet-req-nowait
perf_run
