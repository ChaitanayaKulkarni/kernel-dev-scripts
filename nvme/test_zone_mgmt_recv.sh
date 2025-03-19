# call increatemtal report zone starting from 0 to Nth zone

nr_zones=32
report_zone_header=64
data_len=$(($report_zone_header+$nr_zones*64))
zsze_lba=$((64*1024*1024/4096))

for zno in `seq 0 31`; do
	let zslba=${zsze_lba}*${zno}

	nvme zns zone-mgmt-recv /dev/nvme1n1 --start-lba=${zslba} \
					     --zra=0x00 \
					     --data-len=${data_len} \
					     --zrasf=0x00 \
					     -p
done 

# decrementing data len
for zno in `seq 0 31`; do
	let zslba=${zsze_lba}*${zno}

	nvme zns zone-mgmt-recv /dev/nvme1n1 --start-lba=${zslba} \
					     --zra=0x00 \
					     --data-len=${data_len} \
					     --zrasf=0x00 \
					     -p
	let data_len=data_len-64
done 

# nr_zones should report 0 as we can only read report zone header
nvme zns zone-mgmt-recv /dev/nvme1n1 --start-lba=${zslba} \
				     --zra=0x00 \
				     --data-len=${data_len} \
				     --zrasf=0x00 \
				     -p
echo $data_len

data_len=$(($report_zone_header+$nr_zones*64))

for zno in `seq 0 31`; do
	let zslba=${zsze_lba}*${zno}

	nvme zns zone-mgmt-recv /dev/nvme1n1 --start-lba=${zslba} \
					     --zra=0x00 \
					     --data-len=${data_len} \
					     --zrasf=0x00
done 

# decrementing data len
for zno in `seq 0 31`; do
	let zslba=${zsze_lba}*${zno}

	nvme zns zone-mgmt-recv /dev/nvme1n1 --start-lba=${zslba} \
					     --zra=0x00 \
					     --data-len=${data_len} \
					     --zrasf=0x00
	let data_len=data_len-64
done 

# nr_zones should report 1 as we can only read report zone header
# but since partial bit is on there is one zone matches the criteria
# with zslba pointing to start of the last zone
nvme zns zone-mgmt-recv /dev/nvme1n1 --start-lba=${zslba} \
				     --zra=0x00 \
				     --data-len=${data_len} \
				     --zrasf=0x00
echo $data_len
