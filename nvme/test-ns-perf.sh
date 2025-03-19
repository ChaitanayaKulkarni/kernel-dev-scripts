test_perf()
{
        git log -1
        ./compile_nvme.sh
        sleep 1
	./bdev.sh 1 
	sleep 1
	pahole target/nvmet.ko | grep "struct nvmet_ns {" -A 42 > ${1}-nvme-pahole.c
        for i in 1 2 3 
        do
               perf stat -o ${1}-nvme-cache.${i}.perf -B -e \
		       cache-references,cache-misses,cycles,instructions,branches,faults,migrations \
		       fio fio/randread-iouring.fio --filename=/dev/nvme1n1 --output=${1}-nvme.${i}.fio
        done
	./delete.sh 1
}

git checkout nvme-6.4
test_perf default
git checkout nvmet-nguid-alloc
test_perf nvmet-nguid-alloc

