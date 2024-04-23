#!/bin/bash

cat ./access.log | awk '{print $9}' | grep -Eo "[0-9]{3}" | sort | uniq > tmpall
cat ./access.log | awk '{print $9}' | grep -Eo "(3|4|5)[0-9]{2}" | sort | uniq > tmp
cat ./access.log | awk '{print $4}' | grep -Eo "[0-9]{2}\/[A-Z][a-z]{2}\/[0-9]{4}.*" | sort | awk 'NR == 1{print} END{print}'
startLine="$(cat tmptime | awk 'NR == 1{print}')"
endLine="$(cat tmptime | awk 'END{print}')"
echo "Ошибки запросов с ${startLine} до ${endLine} -"
echo коды возврата ошибок:.
cat tmp
echo ----------------------------------------------------
echo все коды возврата:.
cat tmpall

rm -rf tmp
rm -rf tmpall
rm -rf tmptime
