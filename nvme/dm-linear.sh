#!/bin/bash

if [ $# != 3 ]; then
    echo "Usage: $0 <disk> <num conv zones> <num seq zones>"
    exit 1
fi

disk="$1"
nrconv=$2
nrseq=$3
dname="`basename ${disk}`"

# Linear table entries: "start length linear device offset"
# start: starting block in virtual device
# length: length of this segment
# device: block device, referenced by the device name or by major:minor
# offset: starting offset of the mapping on the device

convlen=$(( $nrconv * 524288 ))
seqlen=$(( $nrseq * 524288 ))

if [ $convlen -eq 0 ] && [ $seqlen -eq 0 ]; then
    echo "0 zones..."
    exit 1
fi

seqofst=`blkzone report $1 | grep -i "Seq_write_required" | head -n1 | cut -f5 -d',' | cut -f3 -d' '`
if [ $convlen -gt $seqofst ]; then
    nrconv=$(( $seqofst / 524288 ))
    echo "Too many conventional zones requested: truncating to $nrconv"
    convlen=$seqofst
fi

if [ $convlen -eq 0 ]; then

echo "0 ${seqlen} linear ${disk} ${seqofst}" | dmsetup create small-${dname}

elif [ $seqlen -eq 0 ]; then

echo "0 ${convlen} linear ${disk} 0" | dmsetup create small-${dname}

else

echo "0 ${convlen} linear ${disk} 0
${convlen} ${seqlen} linear ${disk} ${seqofst}" | dmsetup create small-${dname}

fi
