#!/bin/bash
# Port locker service
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in

# ---------------------------------------------------------- VARIABLES #
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPTPATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

CURRENTCONFIG=""
DOWNLOADCONFIG="download.local"
FIREWALLDUMP="firewall-dump"

# Use local config or no
BLOCKLOCALCONFIG=false
# Source links is down by default
DOWN=true

# ---------------------------------------------------------- FUNCTIONS #

checkServerUptime() {
    echo "Check uptime server"
}


applyConfig() {
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


getDate() {
        dte=$(date +%d-%m-%Y-%H:%M:%S)
        echo $dte
}


writeLog() {
        echo -e "$1" >> "$2"
}


checkSourceDown() {
	RES=$(curl -Is $1 | head -n 1 | grep "200" | wc -l)
	# echo $RES
	if [[ $RES -eq "1" ]]; then
		return 0
	else
		return 1
	fi
}

# 
checkConfigSource() {

    for i in ${SOURCE[@]}; do

        # Extract domain from link
        # DOMAIN=$(echo $i | awk -F/ '{print $3}')
        # Extract fro http
        DOMAIN=$(echo $i | grep -Eo '(http|https)://[^/"]+')
        # Extract link as http://link then check him available
        # DOMAIN=$(echo "${i%/*}")

        if checkSourceDown $DOMAIN; then

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
                        if checkSourceDown $url; then
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


lockPORT() {
    
    # Create dump from current firewalld zone
    firewall-cmd --list-all > $SCRIPTPATH/$FIREWALLDUMP

}


loop()
{
    while true
    do
      	writeLog "$(getDate) Script started" $LOG

        sleep $INTERVAL
    done
}



# ---------------------------------------------------------- START / STOP #

# START

if [ "$1" = "start" ]; then

    # Apply current configs
    applyConfig
    # Check, download and apply new config from source
    checkConfigSource

    # Export firewall config
    firewall-cmd --list-all >> $SCRIPTPATH/conf.d/firewall_history

    # Read and apply current lock parameters from config
    for p in ${PORTLOCK[@]}; do
        
        # Get current firewall settings
        pp=$(firewall-cmd --list-all | grep $p)

        if [[ ! -z $pp ]]; then

            if [[ $pp == *"services"*  ]]; then

                # Not permanent
                echo "Service action!! - $p"
                firewall-cmd --remove-service=$p

            elif [[ $pp == *"ports"* ]]; then
                
                # Not permanent
                echo "Port action!! -$p"
                firewall-cmd --remove-port=$p
            fi

        fi

    done

    # Read and apply port open for ip
    for i in $IP; do
        echo $i

        for p in ${PORTOPEN[@]}; do
            echo $p

            # firewall-cmd --add-rich-rule 'rule family="ipv4" source address="$i" service name="$p" accept'

            # firewall-cmd --add-rich-rule 'rule family="ipv4" source address="$i" port port="$p" protocol="tcp|udp" accept'

        done

    done

    

    # Add check firewall

    #loop &

    # echo $CURRENTCONFIG
    echo Done

fi

# STOP

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
        firewall-cmd --reload
    fi



    echo "Exit"
    exit 1
fi

if [[ -z "$1" ]]; then
	echo "Usage - ./plock.sh start"
fi

# ---------------------------------------------------------- FOOTER #


# wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=<DOCUMENT ID>' -O plock-default.local
#
    # echo $SOURCE
    # echo $INTERVAL
    # echo ${PORTOPEN[*]}
    # echo $IP

    # # After apply new config check SOURCE variable, if empty apply default conf
    # if [[ -z $SOURCE ]]; then
    #     . $SCRIPTPATH/conf.d/plock.conf
    #     CURRENTCONFIG="$SCRIPTPATH/conf.d/plock.conf"

    #     # delete bad local config
    #     rm -rf $SCRIPTPATH/conf.d/$DOWNLOADCONFIG
    #     rm -rf $SCRIPTPATH/conf.d/plock.local

    # fi