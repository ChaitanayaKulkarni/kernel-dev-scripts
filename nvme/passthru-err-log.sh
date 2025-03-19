CTRL_LOGGING=/sys/class/nvme/nvme0/passthru_err_log_enabled
NS_LOGGING=/sys/class/nvme/nvme0/nvme0n1/passthru_err_log_enabled

err_exit()
{
	echo "FAIL"
	exit 1
}

modprobe -r nvme
modprobe nvme

# Test ctrl logging has no effect on ns logging attribute 
# enable ctrl logging
cat ${CTRL_LOGGING} | grep -q off || err_exit 
echo 1 > ${CTRL_LOGGING} 
# make sure ctrl logging is on and ns logging is off
cat ${CTRL_LOGGING} | grep -q on || err_exit
cat ${NS_LOGGING}   | grep -q off || err_exit
# disable ctrl logging 
echo 0 > ${CTRL_LOGGING}
cat ${CTRL_LOGGING} | grep -q off || err_exit

# Test ns logging has no effect on ns logging attribute 
# make sure ns logging is off 
cat ${NS_LOGGING}   | grep -q off || err_exit
# turn on ns logging 
echo 1 > ${NS_LOGGING}
# make sure ctrl logging is off 
cat ${CTRL_LOGGING} | grep -q off || err_exit
# make sure ns logging is on
cat ${NS_LOGGING}   | grep -q on || err_exit  
# turn off ns logging 
echo 0 > ${NS_LOGGING}
# make sure ns logging is off
cat ${NS_LOGGING}   | grep -q off || err_exit

#enable both ctrl and ns 
# make sure ctrl and ns logging is off
cat ${CTRL_LOGGING} | grep -q off || err_exit
cat ${NS_LOGGING}   | grep -q off || err_exit
# turn on ctrl logging and make sure it's on 
echo 1 > ${CTRL_LOGGING}
cat ${CTRL_LOGGING} | grep -q on || err_exit
# turn on ns logging and make sure it is on 
echo 1 > ${NS_LOGGING}
cat ${NS_LOGGING}   | grep -q on || err_exit

# disable both ctrl and ns 
echo 0 > ${CTRL_LOGGING}
cat ${CTRL_LOGGING} | grep -q off || err_exit 
cat ${NS_LOGGING}   | grep -q on || err_exit
echo 0 > ${NS_LOGGING}
cat ${CTRL_LOGGING} | grep -q off || err_exit
cat ${NS_LOGGING}   | grep -q off || err_exit

echo "PASS"
modprobe -r nvme
