git log -1 
./compile_nvme.sh
for i in `seq 1 5` ; do
	fio fio/randread.fio --filename=/dev/nvme0n1 \
	                      --ioengine=io_uring \
			      --output=nvme-prp-2-default.$i.fio
done

git am ./0001-nvme-pci-prp-2-optimization.patch
git log -1 
./compile_nvme.sh
for i in `seq 1 5` ; do
	fio fio/randread.fio --filename=/dev/nvme0n1 \
			     --ioengine=io_uring \
			     --output=nvme-prp-2-directmap.$i.fio
done
