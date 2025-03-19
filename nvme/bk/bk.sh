set -x 

delete_fabric()
{
	nvme delete-ns /dev/nvme1 -n 1 
	sleep 1 
	nvme disconnect -n fs
	sleep 2
	rm -fr /sys/kernel/config/nvmet/ports/1/subsystems/fs
	sleep 2
	rmdir /sys/kernel/config/nvmet/ports/1
	sleep 2
	rmdir /sys/kernel/config/nvmet/subsystems/fs
}


modprobe nvme
modprobe nvme-fabrics
modprobe nvmet
#rm -fr /mnt/nvme0n1/nvme1n*
sleep 2 

tree /sys/kernel/config
#read next

mkdir /sys/kernel/config/nvmet/fs/file

sleep 1
echo -n "/mnt/nvme0n1/" > /sys/kernel/config/nvmet/fs/file/attr_fs_path
#echo -n "/mnt/" > /sys/kernel/config/nvmet/fs/file/attr_mount_path
sleep 1
#echo "cretae ns using nvme cli "
#read next 

mkdir /sys/kernel/config/nvmet/ports/1/
##read next 
echo -n "loop" > /sys/kernel/config/nvmet/ports/1/addr_trtype 
##read next 
#
echo -n 1 > /sys/kernel/config/nvmet/fs/file/attr_allow_any_host
##read next 
#
ln -s /sys/kernel/config/nvmet/fs/file /sys/kernel/config/nvmet/ports/1/subsystems/
#sleep 2
#
echo  "transport=loop,nqn=file" > /dev/nvme-fabrics
sleep 1
ls /dev/nvme*
nvme list
#
#nvme create-ns /dev/nvme1 --nsze=204800 --ncap=204800 --flbas=9
##nvme create-ns /dev/nvme1 --nsze=1048576 --ncap=1048576 --flbas=9
#nvme create-ns /dev/nvme1 --nsze=26214400 --ncap=19660800 --flbas=12
#nvme create-ns /dev/nvme1 --nsze=19660800 --ncap=19660800 --flbas=12
#sleep 1
#nvme list
