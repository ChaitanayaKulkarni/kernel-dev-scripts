fio  --cpus_allowed_policy=split --cpus_allowed=0-7  --group_reporting \
--rw=randread --bs=4k --numjobs=8 --iodepth=128 --runtime=30 --time_based \
--ramp_time=8 --loops=1 --ioengine=libaio --direct=1 --invalidate=1 \
--randrepeat=1 --norandommap --exitall --name task_nvme0n1 --filename /dev/nvme1n1
