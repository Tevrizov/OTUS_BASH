#!/bin/bash
sh /home/tep/scriptip.sh > parse.txt
sh /home/tep/scripturl.sh >> parse.txt
sh /home/tep/error.sh >> parse.txt

cat parse.txt
rm parse.txt
