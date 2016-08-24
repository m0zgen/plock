#!/bin/bash

. conf.rc
settings_global
echo $value1 #outputs 1
LOCALVALUE=$value1
LOCALIP1=$LOCALIP
echo $LOCALIP


settings_system
echo $value1 #outputs 2
LOCALVALUE2=$value1
echo $LOCALIP

echo "$LOCALVALUE - $LOCALVALUE2 - $LOCALIP1 - $LOCALIP"