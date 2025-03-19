for i in 1 2 3 4 5 6 7 8 9 A B C D E F
do
	set +x
	./blktrace/blktrace -P -E -y zone_append -y zone_open -y zone_close -y zone_finish -y zone_reset -y zone_reset_all  -X ${i} -d /dev/nullb0 -o - | blktrace/blkparse -P -E -i - &
	sleep 3

	echo "---------------------------------------------"
	echo "Using Priority mask 0x${i}"
	echo "---------------------------------------------"
	for prio in `seq 0 3`
	do
	 	ionice -c ${prio} blkzone reset /dev/nullb0
	 	ionice -c ${prio} blkzone open /dev/nullb0
	 	ionice -c ${prio} blkzone close /dev/nullb0
	 	ionice -c ${prio} blkzone finish /dev/nullb0
	done
	killall blktrace
	killall blktrace
	killall blktrace
	sleep 3
	set -x
done
