nvme write-zeroes /dev/nvme1n1 -s 0 -b 10 
nvme dsm /dev/nvme1n1 --ad --blocks=0,100,100,100 --slbs=0,1000,2000,3000
nvme flush /dev/nvme1n1  

