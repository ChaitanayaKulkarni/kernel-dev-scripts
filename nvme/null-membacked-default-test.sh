set -x 

modprobe  -r null_blk
modprobe  null_blk
tree config/
lsblk | grep null
fio fio/verify.fio --filename=/dev/nullb0  --output=/tmp/fio.log
grep "err=" /tmp/fio.log
modprobe  -r null_blk

modprobe  -r null_blk
modprobe  null_blk memory_backed=1
tree config/
lsblk | grep null
fio fio/verify.fio --filename=/dev/nullb0  --output=/tmp/fio.log
grep "err=" /tmp/fio.log
modprobe  -r null_blk

