#!/bin/bash

./blktrace/blktrace -P -a $1 -X  $2 -d /dev/nullb0 -o - | blktrace/blkparse -p -i - 
