#!/bin/bash
# Port locker service
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in

# Environments
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Variables
LOG="/var/log/plock.log"
INTERVAL="5"

CHECKLINK="https://sys-adm.in/robots.txt"
PORTLOCK=(ssh 22/tcp)

# Functions
getDate() {
        dte=$(date +%d-%m-%Y-%H:%M:%S)
        echo $dte
}

writeLog() {
        echo -e "$1" >> "$2"
}

checkLINKDOWN() {
	RES=$(curl -Is $CHECKLINK | head -n 1 | grep "200" | wc -l)
	echo $RES
	if [[ $RES -eq "1" ]]; then
		return 0
	else
		return 1
	fi
}

# Actions
loop()
{
    while true
    do
      	writeLog "$(getDate) Script started" $LOG
        sleep $INTERVAL
    done
}



# Work parameters
if [ "$1" = "start" ]; then
    # loop &
    # echo "Enable loop"

    if checkLINKDOWN; then
    	
    	

    else
    	echo "Site is down"
    fi
fi

if [ "$1" = "stop" ]; then
    echo "Exit"
    exit 1
fi
