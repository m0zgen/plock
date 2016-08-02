#!/bin/bash
# Port locker service
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in

# Environments
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPTPATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

CURRENTCONFIG=""
DOWNLOADCONFIG="download.local"

# Variables
# LOG="/var/log/plock.log"
# INTERVAL="5"

# SOURCE="http://forum.sys-admin.kz/robots.txt https://docs.google.com/uc?export=download&id=0B_oezPrKERL8dDZGQ1hjQTFBQjQ"
# PORTLOCK=(ssh 22/tcp)
DOWN=true


#wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=0B_oezPrKERL8dDZGQ1hjQTFBQjQ' \
#-O FILENAME
# wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=0B_oezPrKERL8dDZGQ1hjQTFBQjQ' -O plock-default.local

applyCONFIG() {
    if [ -n "$(ls -A $SCRIPTPATH/conf.d/plock.local)" ]
    then
      echo "Local configuration found. Plock use plock.local"
      . $SCRIPTPATH/conf.d/plock.local
      CURRENTCONFIG="$SCRIPTPATH/conf.d/plock.local"
    else
      # echo "empty (or does not exist)"
      echo "Local configuration not found. Plock use plock.conf"
      . $SCRIPTPATH/conf.d/plock.conf
      CURRENTCONFIG="$SCRIPTPATH/conf.d/plock.conf"
    fi
}

# Functions
getDate() {
        dte=$(date +%d-%m-%Y-%H:%M:%S)
        echo $dte
}

writeLog() {
        echo -e "$1" >> "$2"
}

checkSOURCEDOWN() {
	RES=$(curl -Is $1 | head -n 1 | grep "200" | wc -l)
	# echo $RES
	if [[ $RES -eq "1" ]]; then
		return 0
	else
		return 1
	fi
}

checkFIREWALLD() {

    if [[ -z $(firewall-cmd --list-all | grep -E 'services.*$i') ]]
    then
        echo "Found services"
    fi

    if [[ -z $(firewall-cmd --list-all | grep -E 'ports.*$i') ]]
    then
        echo "Found ports"
    fi

}

kiilMe() {
    echo killme
}

# Actions
# Check SOURCE up status and download config
# compareCONFIG() {

# }

checkSOURCESTATUS() {

    for i in ${SOURCE[@]}; do

        # Extract domain from link
        # DOMAIN=$(echo $i | awk -F/ '{print $3}')
        # Extract fro http
        DOMAIN=$(echo $i | grep -Eo '(http|https)://[^/"]+')
        # Extract link as http://link then check him available
        # DOMAIN=$(echo "${i%/*}")

        if checkSOURCEDOWN $DOMAIN; then

            DOWN=false

            if [[ "$DOWN" = false ]]; then

                # Download file from link
                wget -q --no-check-certificate $i -O $SCRIPTPATH/conf.d/$DOWNLOADCONFIG

                # Check valid config
                sourcelist=(`cat $SCRIPTPATH/conf.d/$DOWNLOADCONFIG`)

                for i in ${sourcelist[@]}; do

                    url=$(echo $i | grep SOURCE | grep -o -P '(?<=").*(?=")')

                    if [[ ! -z $url ]]; then
                        # If contain source link
                        if checkSOURCEDOWN $url; then
                            echo "Link work"

                            # If valid - compare new and current config file
                            diff $SCRIPTPATH/conf.d/$DOWNLOADCONFIG $CURRENTCONFIG

                            # If config not equal, apply new config
                            if [[ $? -ne 0 ]] ;then
                                echo "Apply new config"
                                cp $SCRIPTPATH/conf.d/download.local $SCRIPTPATH/conf.d/plock.local

                                . $SCRIPTPATH/conf.d/plock.conf
                                CURRENTCONFIG="$SCRIPTPATH/conf.d/plock.conf"
                                echo "Config updated and changed to - $CURRENTCONFIG"
                            break
                            fi
                        fi

                    fi

                done
            fi

        else
            echo "$DOMAIN - Site is down"
        fi

    done

}

loop()
{
    while true
    do
      	writeLog "$(getDate) Script started" $LOG



        sleep $INTERVAL
    done
}



# Start parameters
if [ "$1" = "start" ]; then

    applyCONFIG
    checkSOURCESTATUS

    # # After apply new config check SOURCE variable, if empty apply default conf
    # if [[ -z $SOURCE ]]; then
    #     . $SCRIPTPATH/conf.d/plock.conf
    #     CURRENTCONFIG="$SCRIPTPATH/conf.d/plock.conf"

    #     # delete bad local config
    #     rm -rf $SCRIPTPATH/conf.d/$DOWNLOADCONFIG
    #     rm -rf $SCRIPTPATH/conf.d/plock.local

    # fi

    # Export firewall config
    firewall-cmd --list-all >> $SCRIPTPATH/conf.d/firewall_history

    # Add check firewall

    #loop &

    # echo $CURRENTCONFIG
    echo Done

fi

if [ "$1" = "stop" ]; then

    # In running custom
    if [[ -z $(ps -ef | grep "\./plock.sh start" | grep -v grep) ]]
    then
       echo -e "Not running"
    else
       echo -e "Service running kill him..."
           # In running custom
        PIDLIST=$(ps -ef | grep "\./plock.sh start" | grep -v grep | awk '{print $2}')
        for i in $PIDLIST; do
            echo "Kill PID $i"
            kill -9 $i
        done
    fi



    echo "Exit"
    exit 1
fi

if [[ -z "$1" ]]; then
	echo "Usage - ./plock.sh start"
fi
