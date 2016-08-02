#!/bin/bash
# Port locker service
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in

# Environments
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Variables
LOG="/var/log/plock.log"
INTERVAL="5"

CHECKLINKS="https://sys-adm.in/robots.txt https://docs.google.com/uc?export=download&id=0B_oezPrKERL8dDZGQ1hjQTFBQjQ"
PORTLOCK=(ssh 22/tcp)

#wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=0B_oezPrKERL8dDZGQ1hjQTFBQjQ' \
#-O FILENAME
# wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=0B_oezPrKERL8dDZGQ1hjQTFBQjQ' -O plock-default.local


# Functions
getDate() {
        dte=$(date +%d-%m-%Y-%H:%M:%S)
        echo $dte
}

writeLog() {
        echo -e "$1" >> "$2"
}

checkLINKDOWN() {
	RES=$(curl -Is $CHECKLINKS | head -n 1 | grep "200" | wc -l)
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
    loop &
    # echo "Enable loop"

    if checkLINKDOWN; then
    	
    	echo "Action"

    else
    	echo "Site is down"
    fi
fi

if [ "$1" = "stop" ]; then
    echo "Exit"
    exit 1
fi

if [[ -z "$1" ]]; then
	echo "Usage - ./plock.sh start"
fi
