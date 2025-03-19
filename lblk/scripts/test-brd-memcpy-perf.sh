
test_perf()
{
	git log --oneline -2
	./compile_brd.sh
	modprobe brd rd_nr=1 rd_size=$((20*1024*1024))
	sleep 1

	fio fio/randwrite.fio --filename=/dev/ram0
	for i in 1 2 3
	do
		fio fio/randread.fio --filename=/dev/ram0 --output=$1-brd.${i}.fio
	done

	modprobe -r brd
}

git checkout for-next
test_perf default
git checkout brd-memcpy
test_perf with-memcpy
modprobe brd rd_nr=1 rd_size=$((20*1024*1024))
fio fio/verify.fio --filename=/dev/ram0
modprobe -r brd
