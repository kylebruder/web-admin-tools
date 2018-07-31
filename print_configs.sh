#!/bin/bash
# A script to print out all of the configuration that have been modified in the past x days
# Use the number of days as the argument
# By kbruder@cloudbrigade.com
find /etc/  -type f -mtime -"$1" | grep -v "shadow" > configs.txt
while read x; do
        echo "|---------------------------------------|"
        echo ""
        echo $x
        echo ""
        cat $x
done < configs.txt