#!/bin/bash
set -x 
rmmod host/test_verify.ko
./delete.sh
./compile_nullb.sh
./nvme_compile.sh
./bdev.sh 0
set +x 
