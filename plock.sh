#!/bin/bash
# Port locker service
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

LOG="/var/log/plock.log"

getDate() {
        dte=$(date +%d-%m-%Y-%H:%M:%S)
        echo $dte
}

writeLog() {
        echo -e "$1" >> "$2"
}

loop()
{
    while true
    do
      	writeLog "$(getDate) Script started" $LOG
        sleep 5
    done
}


if [ "$1" = "start" ]; then
    loop &
fi

if [ "$1" = "stop" ]; then
    echo "Exit"
    exit 1
fi
