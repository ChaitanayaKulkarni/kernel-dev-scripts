#!/bin/bash -x

unload()
{
	umount /mnt/nvme0n1
	./delete.sh
	#./passthru_clear.sh
	echo "############################## UNLOAD #############################"
	for mod in nvme_loop nvmet nvme_tcp nvme_fabrics nvme nvme_core nvme_keryring nvme_auth; do
		echo "### $mod unload "
		modprobe -r "${mod}"
	done

#	modprobe -r nvme-tcp
#	modprobe -r nvme_loop
#	modprobe -r nvmet
#	modprobe -r nvme
#	modprobe -r nvme-fabrics
	sleep 1
#	modprobe -r nvme-core
	lsmod | grep nvme
	git diff
}

clean()
{
	make -j $(nproc) M=drivers/nvme/target/ clean
	make -j $(nproc) M=drivers/nvme/host/ clean
}

build_warn()
{
	make W=1 C=1 -j $(nproc) M=drivers/nvme/ modules 2>&1 | \
	     grep -v -e generic-non-atomic.h \
                     -e bitops.h \
		     -e nstrumented-non-atomic.h 
}

install()
{
	LIB="/lib/modules/$(uname -r)/kernel/drivers/nvme"
	HOST=drivers/nvme/host
	TARGET=drivers/nvme/target
	HOST_DEST=${LIB}/host/
	TARGET_DEST=${LIB}/target/

	cp ${HOST}/*.ko ${HOST_DEST}/
	cp ${TARGET}/*.ko ${TARGET_DEST}/
	ls -lrth $HOST_DEST $TARGET_DEST/ 
	sync
}

unload

while getopts ":cw" option; do
  case $option in
    c) clean ;;
    w) clean; build_warn ;;
    :) echo "Error: -$OPTARG requires an argument." >&2 ;;
  esac
done

make -j $(nproc) M=drivers/nvme/ modules

install

modprobe nvme-core
modprobe nvme #poll_queues=$(nproc)
modprobe nvme-fabrics
modprobe nvme-tcp
modprobe nvme_loop
modprobe nvmet
dmesg -c
#echo "Press enter to continue ..."
#read next
