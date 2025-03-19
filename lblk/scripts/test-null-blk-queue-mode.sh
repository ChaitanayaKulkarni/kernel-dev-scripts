set +x 
test_mod_param()
{
	./compile_nullb.sh
	for i in 0 1 2
	do
		echo "---------------queue mode $i--------------------"
		modprobe null_blk queue_mode=$i memory_backed=1 gb=1
		if [ $? == 0 ] && [ ! -f /dev/nullb0 ]; then 
			sleep 1
			lsblk
			fio fio/verify.fio --filename=/dev/nullb0
		fi
		modprobe -r null_blk 
		dmesg -c 
		echo "-----------------------------------"
	done
}

modprobe -r null_blk
git checkout for-next
test_mod_param
git checkout nullb-queue-mode
test_mod_param
