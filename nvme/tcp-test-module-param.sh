#!/bin/bash +x

test_param()
{
	modprobe -r nvmet-tcp
	./compile_nvme.sh
	dmesg -c > /dev/null
	for param in so_priority idle_poll_period_usecs
	do
		for val in -2 -1 0 1 100
		do
			modprobe nvmet-tcp $param=$val
			echo "modprobe nvmet-tcp $param=$val returned $?"
			dmesg -c
			modprobe -r nvmet-tcp
		done
	done
	modprobe -r nvmet-tcp
}

echo "####################################"
echo "Without this patch series "
test_param
echo "####################################"
echo "With this patch series "
git am p/tcp-modpram-fix/*patch ; git am --skip
test_param

git reset HEAD~2 --hard


