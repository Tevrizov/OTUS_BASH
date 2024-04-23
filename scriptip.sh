#!/bin/bash

cat /home/tep/access.log | awk '{print $4}' | grep -Eo "[0-9]{2}\/[A-Z][a-z]{2}\/[0-9]{4}.*" | sort | awk 'NR == 1{print} END{print}' > tmptime
start="$(cat tmptime | awk 'NR == 1{print}')"
finish="$(cat tmptime | awk 'END{print}')"
echo "from ${start} to ${finish}:"

cat /home/tep/access.log | awk -F " " '{print $1  }' | sort | uniq -c > tmp
echo "Count ip > 10"
cat tmp | awk '{
if ($1 > 10) 
print $1 " repeats with ip: " $2
}' 
rm -f tmp