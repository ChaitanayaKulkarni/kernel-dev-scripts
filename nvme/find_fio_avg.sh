
for i in nvme-prp-2-default nvme-prp-2-directmap
do
        bw=0
#	echo -n "########### $i ################"
        for j in `grep BW ${i}*fio | column -t  | tr -s ' ' ' ' | cut -f 3 -d '=' | cut -f 1 -d 'M'`
        do
       		echo -n "$j + "
                let bw=bw+$j
                bw=`echo $bw+$j | bc`
        done
	echo ""
        echo "Average Bandwidth $i `echo "scale=5; $bw/5" | bc`"
done

for i in nvme-prp-2-default nvme-prp-2-directmap
do
        iops=0
#	echo -n "########### $i ################"
        for j in `grep IOPS ${i}*fio | column -t  | tr -s ' ' ' ' | cut -d ' ' -f 3 | cut -d '=' -f 2 | cut -f 1 -d 'k'`
        do
	       	echo -n "$j + "
                iops=`echo $iops+$j | bc`
        done
	echo ""
        echo "Average IOPS $i `echo "scale=5; $iops/5" | bc`"
done

<<COMM
for i in nvme-alloc-default nvme-alloc-likely
do
        cpu=0;
#	echo -n  "########### $i ################"
        for j in `grep cpu ${i}*fio | column -t | tr -s ' ' ' ' | cut -f 3 -d '=' | cut -f 1 -d '%'`
        do
#		echo -n "$j + "
                cpu=`scale=5; echo $cpu + $j | bc`

        done;
	echo ""
        echo "Average CPU sys util $i `echo "scale=5; $cpu/10" | bc`"
done


for i in nvme-alloc-default nvme-alloc-likely
do
        lat=0
#echo -n "########### $i ################"

for j in `grep -w  "lat" ${i}*fio | grep avg | tr -s ' ' ' ' |                                       cut -f 6 -d ' ' | cut -f 2 -d '='  | cut -f 1 -d ','`
do
		echo -n "$j + "
                lat=`echo "scale=5; $lat + $j" | bc`
        done;
	echo ""
        echo "Average lat util $i `echo "scale=5; $lat/10" | bc`"
done



#Lat
#for j in `grep -w  "lat" ${i}*fio | grep avg | tr -s ' ' ' ' |                                       cut -f 6 -d ' ' | cut -f 2 -d '='  | cut -f 1 -d ','`
#Slat
# for j in `grep slat ${i}*fio | tr -s ' ' ' ' | awk '{print $7}' | cut -f 2 -d '=' | cut -f 1 -d ','`

COMM
