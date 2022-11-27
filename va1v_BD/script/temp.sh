#!/bin/bash
INTV=${1:-2}
CARD=${2:-va1v_ai0}
DIR="logs/$CARD"
mkdir -p $DIR
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

header=`ipmitool sdr |grep -iE "CPU1 Core|CPU2 Core|gpu|speed|Inlet Temp"|awk -F\| '{print $1}'|sed 's/ //g'|tr '\n' ' '`
echo "Time $header" > $DIR/temp.csv

while true
do
    value=`ipmitool sdr |grep -iE "CPU1 Core|CPU2 Core|gpu|speed|Inlet Temp"|awk -F\| '{print $2}'|awk '{print $1}'|tr '\n' ' '`
    time=`date '+%T'`
	#vas_pwr=`vasmi getpwr -d 0,1`
	#vas_temp=`vasmi gettemp -d 0,1`
    echo "$time $value" >>  $DIR/temp.csv
    sleep $INTV
done