run_fio()
{
	cat  /sys/kernel/config/nvmet/subsystems/x/namespaces/1/use_poll 
	cat  /sys/kernel/config/nvmet/subsystems/x/namespaces/1/device_path 

	for i in 1 2 3 #4 5 #6 7 8 9 10;
	do
		fio fio/randread.fio  --filename=/dev/nvme1n1 --output=$1-${i}.log
	done 
}

./polloff x
run_fio polloff
./pollon x
run_fio pollon
