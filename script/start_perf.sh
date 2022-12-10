#!/bin/bash 
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

CARD=${1:-va1v_ai0}
DIR="logs/$CARD"

mkdir -p $DIR
PCIE=`lspci|grep acc|awk '{print $1}'| tr '\n' ','`
#vasmi dmon -d 0,1,2,3  > $DIR/dmon.log 2>&1 &
mpstat -P ALL 2      > $DIR/cpu.csv  2>/dev/null &
sar -d 2             > $DIR/disk.csv 2>/dev/null &
pmt  --delay=2    --output=$DIR/mem.csv  > /dev/null 2>&1 &
pcie --only=$PCIE --output=$DIR/pcie.csv > /dev/null 2>&1 &
#pcm 2 -nc -nsys  -csv=$DIR/cpu.csv  > /dev/null 2>&1 &
#pcm-pcie     -B  -csv=$DIR/pcie.csv > /dev/null 2>&1 &
#pcm-memory 2 -nc -csv=$DIR/mem.csv  > /dev/null  2>&1 &
#./temp.sh 2 $CARD &
#sleep 30
#perf record -F 99 -ag -o $DIR/perf.data -- sleep 30 &

# vaprofiler --video 5
# vaprofiler --bandwidth
# vaprofiler --bandwidth > $DIR/bw.csv 2>&1 &
