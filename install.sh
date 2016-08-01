#!/bin/bash
# Install / Uninstall plock in to system
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPTPATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

SERVICE="plock.service"
SCRIPT="plock.sh"

installPlock() {

	if [[ ! -f /etc/systemd/system/$SERVICE ]]; then
		cp $SCRIPTPATH/$SERVICE /etc/systemd/system/$SERVICE
		cp $SCRIPTPATH/$SCRIPT /usr/bin/$SCRIPT

		systemctl enable $SERVICE
		systemctl start $SERVICE
		echo "Done!"
	else
		echo "Service already installed"
	fi

	
}

unistallPlock() {

	if [[ -f /etc/systemd/system/$SERVICE ]]; then
		systemctl disable $SERVICE
		systemctl stop $SERVICE
		
		rm -rf /etc/systemd/system/$SERVICE
		rm -rf /usr/bin/$SCRIPT
		systemctl daemon-reload
		echo "Uninstall complete!"
	else
		echo "Service not installed!"
	fi

	
}


startmenu() {
	echo "Press 1 to Install"
	echo "Press 2 tu Uninstall"
	echo -e "Press x to Exit\n"
	read  -p "Enter command: " startmenuinput
	if [ "$startmenuinput" = "1" ]; then
		installPlock
	elif [ "$startmenuinput" = "2" ]; then
		unistallPlock
	elif [ "$startmenuinput" = "x" ];then
            echo -e "Bye bye.."
            exit 1
    else
    	echo "You have entered an invallid selection!"
        echo "Please try again!"
        echo ""
        echo "Press any key to continue..."
        read -n 1
        startmenu
    fi
}

startmenu