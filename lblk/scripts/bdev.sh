set -x 

FILE="/dev/nvme0n1"
#FILE="/dev/nullb0"
NN=$1
NQN=testnqn
let NR_DEVICES=NN+1

modprobe -r null_blk
modprobe null_blk nr_devices=0 verify=$2
modprobe nvme
modprobe nvme-fabrics
modprobe nvmet
modprobe nvme-loop
dmesg -c > /dev/null
sleep 2 

tree /sys/kernel/config

mkdir /sys/kernel/config/nvmet/subsystems/${NQN}

#for i in `shuf -i  1-$NN -n $NN`
#do
#	mkdir /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}
#	echo -n "/dev/nullb${i}" > /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/device_path
# blockdev --setro /dev/nullb${i} 
#	echo 1 > /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/write_protect
#	cat /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/device_path
#	echo 1 > /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/enable 
#done

mkdir /sys/kernel/config/nvmet/ports/1/
echo -n "loop" > /sys/kernel/config/nvmet/ports/1/addr_trtype 
echo -n 1 > /sys/kernel/config/nvmet/subsystems/${NQN}/attr_allow_any_host
ln -s /sys/kernel/config/nvmet/subsystems/${NQN} /sys/kernel/config/nvmet/ports/1/subsystems/
sleep 1
#echo  "transport=loop,nqn=${NQN},keep_alive_tmo=700" > /dev/nvme-fabrics
echo  "transport=loop,nqn=${NQN}" > /dev/nvme-fabrics

for i in `shuf -i  1-$NN -n $NN`
do
	mkdir config/nullb/nullb${i}

#echo 1 > config/nullb/nullb${i}/memory_backed
	#echo 4096 > config/nullb/nullb${i}/blocksize 
	echo 20971520 > config/nullb/nullb${i}/size 
#echo 512000 > config/nullb/nullb${i}/size 
	echo 1 > config/nullb/nullb${i}/discard
	echo 1 > config/nullb/nullb${i}/power
	IDX=`cat config/nullb/nullb${i}/index`
	mkdir /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}

        let IDX=IDX+1
	echo " ####### /dev/nullb${IDX}"
	echo -n "/dev/nullb${IDX}" > /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/device_path
	cat /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/device_path
        echo 1 > /sys/kernel/config/nvmet/subsystems/${NQN}/namespaces/${i}/enable 
	dmesg -c 
done

sleep 1

#nvme discover -t loop >> /tmp/op 2>&1

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
