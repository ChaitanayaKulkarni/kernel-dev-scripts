for j in 64 127 128 129 191 192 193 255 256 257;
do
echo "--------------------- $j--------------------";
for i in `nvme zns report-zones /dev/nvme1n1 | grep 0x | cut -f 2 -d ' '| cut -f 2 -d 'x'`
do
slba_decimal=`echo "ibase=16; $i" | bc`
nvme zns zone-mgmt-recv /dev/nvme1n1 --zra=0x00 --start-lba=${slba_decimal} --data-len=${i} -p
echo ${slba_decimal}
read next
done
done
