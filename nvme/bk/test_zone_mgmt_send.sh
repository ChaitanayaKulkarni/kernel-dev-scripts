NVME_ZONE_CLOSE=0x1
NVME_ZONE_FINISH=0x2
NVME_ZONE_OPEN=0x3
NVME_ZONE_RESET=0x4

blkzone reset /dev/nvme1n1

declare -a zslba_list=($(nvme zns report-zones /dev/nvme1n1 | grep -i slba | tr -s ' ' ' ' | cut -f 2 -d ' '))

report_zones()
{
	nvme zns report-zones /dev/nvme1n1 || echo "ERROR"
}

zmgmt_send()
{
	nvme zns zone-mgmt-send /dev/nvme1n1 --start-lba=$1 --zsa=$2
	report_zones
}

zone_impl_open()
{
	dd if=/dev/zero of=/dev/nvme1n1 bs=4k count=1 oflag=direct 2> /dev/null
	report_zones
}

zone_expl_open()
{
	zmgmt_send 0 $NVME_ZONE_OPEN
}

zone_close()
{
	zmgmt_send 0 $NVME_ZONE_CLOSE
}

zone_finish()
{
	zmgmt_send 0 $NVME_ZONE_FINISH
}

zone_reset()
{
	zmgmt_send 0 $NVME_ZONE_RESET
}

zone_reset_all()
{
	blkzone reset /dev/nvme1n1
	report_zones
}

test_zmgmt_send_open()
{
	echo "############### impl open zone -> expl open "
	zone_reset_all
	zone_impl_open
	zone_expl_open
	echo "############### empty -> expl open "
	zone_reset_all
	zone_expl_open
	echo "############### close -> expl open "
	zone_reset_all
	zone_impl_open
	zone_expl_open
	zone_close
	zone_expl_open
	echo "############### expl open -> exp expl open "
	zone_reset_all
	zone_expl_open
	zone_expl_open
}

test_zmgmt_send_close()
{
	echo "############## impl open zone -> close"
	zone_reset_all
	zone_impl_open
	zone_close
	echo "############## expl open zone -> close, it shuold show empty since zone is empty"
	zone_reset_all
	zone_impl_open
	zone_expl_open
	zone_close
	echo "############## close -> close"
	zone_reset_all
	zone_impl_open
	zone_close
	zone_close
}

test_zmgmt_send_finish()
{
	echo "############## impl open zone -> finish"
	zone_reset_all
	zone_impl_open
	zone_finish
	echo "############## expl open zone -> close -> finish"
	zone_reset_all
	zone_expl_open
	zone_finish
	echo "############## empty -> finish "
	zone_reset_all
	zone_finish
	echo "############## finish -> finish"
	zone_reset_all
	zone_finish
	zone_finish
}

test_zmgmt_send_reset()
{
	echo "############## impl open zone -> empty"
	zone_reset_all
	zone_impl_open
	zone_reset
	echo "############## expl open zone -> empty"
	zone_reset_all
	zone_expl_open
	zone_reset
	echo "############## close -> empty"
	zone_reset_all
	zone_impl_open
	zone_expl_open
	zone_close
	zone_reset
	echo "############# finish -> empty"
	zone_reset_all
	zone_expl_open
	zone_close
	zone_finish
	zone_reset
	echo "############# empty -> empty"
	zone_reset_all
	zone_reset
}

zone_impl_open_all()
{
	blkzone reset /dev/nvme1n1
	for i in "${zslba_list[@]}"; do
		nvme write /dev/nvme1n1 -s ${i} -c 10 --data-size=40960 --data=/dev/zero
	done 
	report_zones
}

zone_open_all()
{
	nvme zns zone-mgmt-send /dev/nvme1n1 -a --zsa=$NVME_ZONE_OPEN
	report_zones
}

zone_close_all()
{
	nvme zns zone-mgmt-send /dev/nvme1n1 -a --zsa=$NVME_ZONE_CLOSE
	report_zones
}

zone_finish_all()
{
	nvme zns zone-mgmt-send /dev/nvme1n1 -a --zsa=$NVME_ZONE_FINISH
	report_zones
}

zone_reset_all()
{
	nvme zns zone-mgmt-send /dev/nvme1n1 -a --zsa=$NVME_ZONE_RESET
	report_zones
}

test_zmgmt_send_open_all()
{
	# implicitly open all the zones 
	zone_impl_open_all
	zone_close_all
	zone_open_all
}

test_zmgmt_send_close_all()
{
	# implicitly open all the zones 
	blkzone reset /dev/nvme1n1
	zone_impl_open_all
	# impl open -> close
	zone_close_all
	# expl open -> close 
	zone_open_all
	zone_close_all
}

test_zmgmt_send_finish_all()
{
	# impl open -> finish
	blkzone reset /dev/nvme1n1
	zone_impl_open_all
	zone_finish_all
	# expl open -> finish 
	blkzone reset /dev/nvme1n1
	zone_impl_open_all
	zone_close_all
	zone_open_all
	zone_finish_all
	# close -> finish 
	blkzone reset /dev/nvme1n1
	zone_impl_open_all
	zone_close_all
	zone_finish_all
}

test_zmgmt_send_reset_all()
{
	# impl open -> empty 
	blkzone reset /dev/nvme1n1
	zone_impl_open_all
	zone_reset_all
	# expl open -> rmpty  
	blkzone reset /dev/nvme1n1
	zone_impl_open_all
	zone_close_all
	zone_open_all
	zone_reset_all
	# close -> empty  
	blkzone reset /dev/nvme1n1
	zone_impl_open_all
	zone_close_all
	zone_reset_all
	# close -> finish
	blkzone reset /dev/nvme1n1
	zone_impl_open_all
	zone_close_all
	zone_finish_all
	zone_reset_all
}

#test_zmgmt_send_open
#test_zmgmt_send_close
#test_zmgmt_send_finish
#test_zmgmt_send_reset

#test_zmgmt_send_open_all
#test_zmgmt_send_close_all
#test_zmgmt_send_finish_all
#test_zmgmt_send_reset_all
