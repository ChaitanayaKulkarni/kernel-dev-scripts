#bin/bash
./delete.sh
./compile_nvme.sh
./bdev.sh
perf record -ag --output=genblk.perf fio fio/randread.fio --filename=/dev/nvme1n1
./delete.sh
perf report --input=genblk.perf --sort=dso

