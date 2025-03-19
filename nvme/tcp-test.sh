#!/bin/bash -x 

modprobe nvme-core
modprobe nvme
modprobe nvme-fabrics
modprobe nvme-tcp
modprobe nvme_loop
modprobe nvmet
# Variables (replace with your setup values)
IP_ADDR="$(hostname -I | awk '{print $1}')"  # Local machine IP
DEVICE="/dev/nvme0n1"  # NVMe device path
PORT=4420  # Single port

export LD_LIBRARY_PATH=/usr/local/lib64/:$LD_LIBRARY_PATH

# Helper function to print messages
echo_msg() {
    echo -e "\n==============================\n$1\n=============================="
}

mkdir -p /sys/kernel/config/nvmet/ports/1
echo -n $IP_ADDR | tee /sys/kernel/config/nvmet/ports/1/addr_traddr > /dev/null
echo -n "tcp" | tee /sys/kernel/config/nvmet/ports/1/addr_trtype > /dev/null
echo -n "ipv4" | tee /sys/kernel/config/nvmet/ports/1/addr_adrfam > /dev/null
echo -n $PORT | tee /sys/kernel/config/nvmet/ports/1/addr_trsvcid > /dev/null

# Step 1: Create 10 Subsystems
for i in {1..5}; do
    SUBSYSTEM="testnqn-$i"

    echo_msg "Setting up Subsystem $SUBSYSTEM on Port PORT"
    mkdir /sys/kernel/config/nvmet/subsystems/$SUBSYSTEM/
    # Create the subsystem
    echo 1 |  tee /sys/kernel/config/nvmet/subsystems/$SUBSYSTEM/attr_allow_any_host > /dev/null

    # Add a namespace
     mkdir -p /sys/kernel/config/nvmet/subsystems/$SUBSYSTEM/namespaces/1
    echo -n $DEVICE |  tee /sys/kernel/config/nvmet/subsystems/$SUBSYSTEM/namespaces/1/device_path > /dev/null
    echo 1 |  tee /sys/kernel/config/nvmet/subsystems/$SUBSYSTEM/namespaces/1/enable > /dev/null

    # Link the subsystem to the port
    ln -s /sys/kernel/config/nvmet/subsystems/$SUBSYSTEM /sys/kernel/config/nvmet/ports/1/subsystems/$SUBSYSTEM

done

# Step 2: Connect to 10 Subsystems
echo_msg "Connecting to 2 NVMe-oF TCP Subsystems"
for i in {1..5}; do
    SUBSYSTEM="testnqn-$i"

    echo_msg "Connecting to Subsystem $SUBSYSTEM on Port $PORT"
     nvme discover -t tcp -a $IP_ADDR -s $PORT || exit 1
     nvme connect -t tcp -n $SUBSYSTEM -a $IP_ADDR -s $PORT || exit 1

done

read next

# Step 3: Disconnect from 10 Subsystems
echo_msg "Disconnecting from 2 NVMe-oF TCP Subsystems"
for i in {1..5}; do
    SUBSYSTEM="testnqn-$i"

    echo_msg "Disconnecting from Subsystem $SUBSYSTEM"
    nvme disconnect -n $SUBSYSTEM || exit 1

done

# Step 4: Clean Up 10 Subsystems
echo_msg "Cleaning Up 2 NVMe-oF TCP Subsystems"
for i in {1..5}; do
    SUBSYSTEM="testnqn-$i"

    echo_msg "Cleaning Up Subsystem $SUBSYSTEM"
    rm -rf /sys/kernel/config/nvmet/ports/1/subsystems/$SUBSYSTEM
    rmdir  /sys/kernel/config/nvmet/subsystems/$SUBSYSTEM/namespaces/*
    rmdir  /sys/kernel/config/nvmet/subsystems/$SUBSYSTEM

done
rmdir /sys/kernel/config/nvmet/ports/1

echo_msg "Script Completed Successfully"

#rm -fr config/nvmet/ports/1/subsystems/testnqn-*
#rmdir  config/nvmet/subsystems/testnqn-*/namespaces/*
#rmdir  config/nvmet/subsystems/testnqn-*

tree /sys/kernel/config/

modprobe -r nvme-tcp
modprobe -r nvme_loop
modprobe -r nvmet-tcp
modprobe -r nvmet
modprobe -r nvme
modprobe -r nvme-fabrics
modprobe -r nvme-core

lsmod | grep nvme
