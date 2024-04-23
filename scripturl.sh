#!/bin/bash
cat /home/tep/access.log | grep -Eo "(http|https)://[a-zA-Z0-9.]*" | sort | uniq -c | sort > tmp
echo "URL > 5"
cat tmp | awk '{
if ($1 > 5) 
print $1 " repeats with URL: " $2
}' 
rm -f tmp
