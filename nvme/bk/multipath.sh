set -x 

NN=2
let NR_DEVICES=NN+1
PORT=/sys/kernel/config/nvmet/ports
NS=/sys/kernel/config/nvmet/subsystems/fs/namespaces

modprobe -r null_blk
modprobe null_blk gb=50 nr_devices=${NR_DEVICES}
modprobe nvme
modprobe nvme-fabrics
modprobe nvmet
modprobe nvme-loop
dmesg -c > /dev/null
sleep 2 

tree /sys/kernel/config

mkdir /sys/kernel/config/nvmet/subsystems/fs

mkdir ${PORT}/1/
echo -n "loop" > ${PORT}/1/addr_trtype 
echo "1" > "${PORT}"/1/addr_traddr
echo -n 1 > /sys/kernel/config/nvmet/subsystems/fs/attr_allow_any_host
mkdir ${PORT}/1/ana_groups/2
ln -s /sys/kernel/config/nvmet/subsystems/fs /sys/kernel/config/nvmet/ports/1/subsystems/

mkdir ${PORT}/2/
echo -n "loop" > ${PORT}/2/addr_trtype 
echo "2" > "${PORT}"/2/addr_traddr
echo -n 1 > /sys/kernel/config/nvmet/subsystems/fs/attr_allow_any_host
mkdir ${PORT}/2/ana_groups/2
ln -s /sys/kernel/config/nvmet/subsystems/fs /sys/kernel/config/nvmet/ports/2/subsystems/

for i in `shuf -i  1-$NN -n $NN`
do
	mkdir ${NS}/${i}
	echo -n "/dev/nullb${i}" > ${NS}/${i}/device_path
	echo -n "$i" > ${NS}/${i}/ana_grpid
	cat ${NS}/${i}/device_path
	echo 1 > ${NS}/${i}/enable 
done



sleep 1
nvme connect -t loop -a 1 -n fs
nvme connect -t loop -a 2 -n fs
sleep 1
