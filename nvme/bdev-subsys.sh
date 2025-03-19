#set -x 

NN=$1
NQN=testnqn
let NR_DEVICES=NN+1

modprobe -r null_blk
modprobe -r nvme
modprobe null_blk nr_devices=0
modprobe nvme #poll_queues=12
modprobe nvme-fabrics
modprobe nvmet
#modprobe nvme-loop
dmesg -c > /dev/null
sleep 1 

tree /sys/kernel/config
mkdir /sys/kernel/config/nvmet/ports/1/
echo -n "loop" > /sys/kernel/config/nvmet/ports/1/addr_trtype 

for i in `seq 1 5`
do 
	mkdir /sys/kernel/config/nvmet/subsystems/${NQN}-${i}

	mkdir /sys/kernel/config/nvmet/subsystems/${NQN}-${i}/namespaces/${NN}
	echo -n "/dev/nvme0n1" > \
		/sys/kernel/config/nvmet/subsystems/${NQN}-${i}/namespaces/${NN}/device_path
	cat /sys/kernel/config/nvmet/subsystems/${NQN}-${i}/namespaces/${NN}/device_path
	echo 1 > /sys/kernel/config/nvmet/subsystems/${NQN}-${i}/namespaces/${NN}/enable 

	echo -n 1 > /sys/kernel/config/nvmet/subsystems/${NQN}-${i}/attr_allow_any_host
	ln -s /sys/kernel/config/nvmet/subsystems/${NQN}-${i} /sys/kernel/config/nvmet/ports/1/subsystems/

	echo  "transport=loop,nqn=${NQN}-${i}" > /dev/nvme-fabrics
done
dmesg -c 
#echo  "transport=loop,nqn=${NQN}" > /dev/nvme-fabrics
#echo  "transport=loop,nqn=${NQN},keep_alive_tmo=700" > /dev/nvme-fabrics

