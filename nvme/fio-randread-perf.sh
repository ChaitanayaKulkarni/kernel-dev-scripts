git log -1 
./compile_nvme.sh
dir_name=$(date +'%Y-%m-%d_%H-%M-%S')-fio-perf

mkdir -p "${dir_name}"

for i in  4 8 16 32 64; do
	echo "------------------------------------------------------------------"
	echo "fio fio/randread.fio --filename=/dev/nvme0n1 --ioengine=io_uring --blocksize=${i}k --output=$(uname -r).${i}.fio"

	fio fio/randread.fio --filename=/dev/nvme0n1 \
	                      --ioengine=io_uring --blocksize=${i}k \
			      --output="${dir_name}/$(uname -r).bs-${i}k.fio"
done
