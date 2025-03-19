#!/bin/bash

DEV=/dev/nvme1n1
ZSZE=16384
ZSLBA=$((ZSZE*10))
NR_ZONEE=`cat /sys/block/nvme1n1/queue/nr_zones`

ALL=0x01  # Not a state
EMPTY=0x01
IMP_OPEN=0x02
EXP_OPEN=0x03
CLOSED=0x04
READONLY=0x05
FULL=0x06
OFFLINE=0x07

ZSA_CLOSE=0x1
ZSA_FINISH=0x2
ZSA_OPEN=0x3
ZSA_RESET=0x4
ZSA_OFFLINE=0x5

test_blkzone_states()
{
	# Empty
	blkzone reset ${DEV}

	nvme zns report-zones ${DEV} -S ${EMPTY}
	nvme zns report-zones ${DEV} -d 10 -s ${ZSLBA} -S ${EMPTY}
	# Explicitly Open 
	blkzone open ${DEV} 
	nvme zns report-zones ${DEV} -S ${EXP_OPEN}
	nvme zns report-zones ${DEV} -d 10 -s ${ZSLBA} -S ${EXP_OPEN}

	# Close
	blkzone close ${DEV} 
	nvme zns report-zones ${DEV} -S ${EMPTY}
	nvme zns report-zones ${DEV} -d 10 -s ${ZSLBA} -S ${EMPTY}

	# Finish
	blkzone finish ${DEV}
	nvme zns report-zones ${DEV} -S ${FULL}
	nvme zns report-zones ${DEV} -d 10 -s ${ZSLBA} -S ${FULL}
}

test_zone_mgmt_send_states()
{
	# Empty
        nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_RESET}
	nvme zns report-zones ${DEV} -S ${EMPTY}
	nvme zns report-zones ${DEV} -d 10 -s ${ZSLBA} -S ${EMPTY}

	# Explicitly Open 
        nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_OPEN}
	nvme zns report-zones ${DEV} -S ${EXP_OPEN}
	nvme zns report-zones ${DEV} -d 10 -s ${ZSLBA} -S ${EXP_OPEN}

	# Close
        nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_CLOSE}
	nvme zns report-zones ${DEV} -S ${EMPTY}
	nvme zns report-zones ${DEV} -d 10 -s ${ZSLBA} -S ${EMPTY}

	# Finish
        nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_FINISH}
	nvme zns report-zones ${DEV} -S ${FULL}
	nvme zns report-zones ${DEV} -d 10 -s ${ZSLBA} -S ${FULL}

	nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZMS_RESET}
}


test_zone_mgmt_recv_pattial()
{
	ZNS_CLOSE=0x1
	ZNS_FINISH=0x2
	ZNS_OPEN=0x3
	ZNS_RESET=0x4
	ZNS_OFFLINE=0x5
	PARTIAL=$1

	# Empty
        nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_RESET}
        nvme zns zone-mgmt-recv ${DEV} --zsa=${ZSA_RESET} -p ${PARTIAL}
	nvme zns report-zones ${DEV} -S ${EMPTY}

	# Explicitly Open 
        nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_OPEN}
        nvme zns zone-mgmt-recv ${DEV} --zsa=${ZSA_OPEN} -p ${PARTIAL}
	nvme zns report-zones ${DEV} -S ${EXP_OPEN}

	# Close
        nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_CLOSE}
        nvme zns zone-mgmt-recv ${DEV} --zsa=${ZMS_RESET} -p ${PARTIAL}
	nvme zns report-zones ${DEV} -S ${EMPTY}

	# Finish
        nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_FINISH}
        nvme zns zone-mgmt-recv ${DEV} --zsa=${ZSA_FINISH} -p ${PARTIAL}
	nvme zns report-zones ${DEV} -S ${FULL}

	# Reset 
	nvme zns zone-mgmt-send ${DEV} -a --zsa=${ZSA_RESET}
}

test_zone_mgmt_recv_states()
{
	test_zone_mgmt_recv_states 0

	# Check correct nr_zones are reported in with partial = 0
	# Should report zones with decreasing number as slba increases
	for i in `nvme zns report-zones /dev/nvme1n1 | grep 0x | cut -f 2 -d ' '| cut -f 2 -d 'x'`
	do 
		slba_decimal=`echo "ibase=16; $i" | bc`
		nvme zns zone-mgmt-recv /dev/nvme1n1 --zra=0x00 \
		--start-lba=${slba_decimal} --data-len=64 -p 0 
	done 

}

main()
{
#	test_blkzone_states
#	test_zone_mgmt_send_states
	test_zone_mgmt_recv_states
}

main
