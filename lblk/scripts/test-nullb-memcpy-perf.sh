test_perf()
{
	git log --oneline -4
	./compile_nullb.sh
	./nullbtests.sh 1
	sleep 1
	lsblk

	fio fio/randwrite.fio --filename=/dev/nullb0 
	for i in 1 2 3
	do
		fio fio/randread.fio --filename=/dev/nullb0 --output=${1}-nullb.${i}.fio
	done

	fio fio/verify.fio --filename=/dev/nullb0
}

git checkout for-next
test_perf default
git checkout null-memcpy-page
test_perf with-memcpy-page
