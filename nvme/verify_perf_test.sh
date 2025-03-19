#!/bin/bash
set -x 
rmmod host/test_verify.ko
./delete.sh; ./bdev.sh 0 
time insmod host/test_verify.ko
./delete.sh; ./bdev.sh 1
rmmod host/test_verify.ko
time insmod host/test_verify.ko
set +x 
