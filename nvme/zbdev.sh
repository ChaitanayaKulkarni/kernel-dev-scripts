set -x 

SUBSYS=/sys/kernel/config/nvmet/subsystems
PORT=/sys/kernel/config/nvmet/ports
NQN=testnqn
NN=1

unload()
{
	modprobe -r null_blk
	modprobe null_blk zoned=1 nr_devices=0
	modprobe nvme
	modprobe nvme-fabrics
	modprobe nvmet
	modprobe nvme-loop
	dmesg -c > /dev/null
	sleep 2 
}

make_subsys()
{
	tree /sys/kernel/config
	mkdir ${SUBSYS}/${NQN}
	echo -n 1 > ${SUBSYS}/${NQN}/attr_allow_any_host
}

make_ns()
{
	for i in `shuf -i  1-$NN -n $NN`
	do
		mkdir config/nullb/nullb${i}

		echo 1 > config/nullb/nullb${i}/memory_backed
		echo 4096 > config/nullb/nullb${i}/blocksize 
		echo 1024 > config/nullb/nullb${i}/size 

		echo 128 > config/nullb/nullb${i}/zone_size
		echo 1 > config/nullb/nullb${i}/zoned
		echo 1 > config/nullb/nullb${i}/power

		IDX=`cat config/nullb/nullb${i}/index`

		mkdir ${SUBSYS}/${NQN}/namespaces/${i}
		echo " ####### /dev/nullb${IDX}"

		echo -n "/dev/nullb${IDX}" > ${SUBSYS}/${NQN}/namespaces/${i}/device_path
		cat ${SUBSYS}/${NQN}/namespaces/${i}/device_path
		echo "${SUBSYS}/${NQN}/namespaces/${i}/enable"
		echo 1 > ${SUBSYS}/${NQN}/namespaces/${i}/enable 
	done
}

make_port()
{
	mkdir ${PORT}/1/
	echo -n "loop" > ${PORT}/1/addr_trtype 
	ln -s ${SUBSYS}/${NQN} ${PORT}/1/subsystems/
	sleep 1
}

connect_host()
{
	echo  "transport=loop,nqn=${NQN}" > /dev/nvme-fabrics
}

main()
{
	unload
	make_subsys
	make_port
	connect_host
	make_ns

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
	ls -lrth /dev/nvme*
}

main
