#!/bin/bash

mdadm --examine /dev/nullb0 /dev/nullb1
mdadm --create /dev/md0 --level=mirror --raid-devices=2 /dev/nullb0 /dev/nullb1
mdadm --detail /dev/md0
