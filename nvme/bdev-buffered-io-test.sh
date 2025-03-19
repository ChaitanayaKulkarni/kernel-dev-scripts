TEST_COUNT=10

./delete.sh 1
./compile_nvme.sh

./delete.sh 1
./bdev.sh 1 1

fio fio/verify.fio --filename=/dev/nvme1n1
for i in `seq 1 ${TEST_COUNT}` ; do fio fio/randwrite.fio --filename=/dev/nvme1n1; done 
for i in `seq 1 ${TEST_COUNT}` ; do fio fio/randread.fio --filename=/dev/nvme1n1; done 

./delete.sh 1
./bdev.sh 1 0

fio fio/verify.fio --filename=/dev/nvme1n1
for i in `seq 1 ${TEST_COUNT}` ; do fio fio/randwrite.fio --filename=/dev/nvme1n1; done 
for i in `seq 1 ${TEST_COUNT}` ; do fio fio/randread.fio --filename=/dev/nvme1n1; done 

