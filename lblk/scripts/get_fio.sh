grep -w -e "lat (usec):"  -e "lat (nsec):"  *nullb*fio | \
	     tr -s ' ' ' ' | cut -f 6 -d ' ' | cut -f 2 -d '=' | cut -f 1 -d ','
grep IOPS *nullb*fio | cut -f 4 -d ' ' | cut -f 2 -d '=' | sed 's/k,//g'
grep cpu  *null*fio | tr -s ' ' ' ' | cut -f 5 -d ' ' | cut -f 2 -d '=' | tr -s ',' ' '| sed 's/%//g'
