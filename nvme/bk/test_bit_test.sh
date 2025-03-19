#!/bin/bash -x

run_perf()
{
	git log --oneline -10
	./delete.sh 1
	./compile_nvme.sh
	./bdev.sh 1
	sleep 1
	for i in 1 2 3
	do
		fio fio/randread.fio --filename=/dev/nvme1n1 --output=$1$i.fio.log
	done
	./delete.sh 1          
}

git co nvme-5.9
run_perf with-default-test-bit

git co delay_test_bit
run_perf with-delayed-test-bit

