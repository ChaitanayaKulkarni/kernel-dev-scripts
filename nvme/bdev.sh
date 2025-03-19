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
#for i in `seq 1 5`
#do 
#	mkdir /sys/kernel/config/nvmet/subsystems/${NQN}-${i}

# /dev/nvme0n1
#	mkdir /sys/kernel/config/nvmet/subsystems/${NQN}-${i}/namespaces/${NN}
#	echo -n "/dev/nvme0n1" > \
#		/sys/kernel/config/nvmet/subsystems/${NQN}-${i}/namespaces/${NN}/device_path
#cat /sys/kernel/config/nvmet/subsystems/${NQN}-${i}/namespaces/${NN}/device_path
#echo 1 > /sys/kernel/config/nvmet/subsystems/${NQN}-${i}/namespaces/${NN}/enable 
#
#mkdir /sys/kernel/config/nvmet/ports/1/
#echo -n "loop" > /sys/kernel/config/nvmet/ports/1/addr_trtype 
#echo -n 1 > /sys/kernel/config/nvmet/subsystems/${NQN}-${i}/attr_allow_any_host
#ln -s /sys/kernel/config/nvmet/subsystems/${NQN}-${i} /sys/kernel/config/nvmet/ports/1/subsystems/
#
#echo  "transport=loop,nqn=${NQN}-${i}" > /dev/nvme-fabrics
#done
#echo  "transport=loop,nqn=${NQN}" > /dev/nvme-fabrics
#echo  "transport=loop,nqn=${NQN},keep_alive_tmo=700" > /dev/nvme-fabrics

mkdir /sys/kernel/config/nvmet/subsystems/${NQN}

mkdir /sys/kernel/config/nvmet/ports/1/
echo -n "loop" > /sys/kernel/config/nvmet/ports/1/addr_trtype 
echo -n 1 > /sys/kernel/config/nvmet/subsystems/${NQN}/attr_allow_any_host
ln -s /sys/kernel/config/nvmet/subsystems/${NQN} /sys/kernel/config/nvmet/ports/1/subsystems/

echo  "transport=loop,nqn=${NQN}" > /dev/nvme-fabrics
sleep 1

for i in `seq 1 $NN`
do
	mkdir config/nullb/nullb${i}
	echo 0 > config/nullb/nullb${i}/memory_backed
#	echo 1 > config/nullb/nullb${i}/discard
	echo 4096 > config/nullb/nullb${i}/blocksize 
	echo 1024 > config/nullb/nullb${i}/size 
	echo 1 > config/nullb/nullb${i}/power
        IDX=`cat config/nullb/nullb${i}/index`
	let IDX=$IDX+1
	mkdir /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}

	echo " ####### /dev/nullb${IDX}"
	echo -n "/dev/nullb${IDX}" > /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/device_path
	cat /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/device_path
	dmesg -c 
done

for i in `seq 1 $NN`
do
	echo 1 > /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/enable 
	sleep 1
done

mount | column -t | grep nvme

while [ 1 ] 
do 
	cnt=`ls -l /dev/nvme1*  |  wc -l`
	echo $cnt
	if [ $cnt -gt ${NN} ]; then
		break;
	fi
	sleep 1
	dmesg -c
done
dmesg -c
