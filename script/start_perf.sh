#!/bin/bash 
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

CARD=${1:-ai_bench.yolov7}
DIR="logs/$CARD"

killall vaprofiler vasmi mpstat pcie mem sar
sleep 5

NAME=`echo $CASE | awk -F. '{print $1}'`

FC=`ls /data|wc -l`
if [ $FC -lt 1 ]; then
  mount -t nfs 192.168.20.2:/nfs/sedata /data
  # cp -r /data/perf_test/ai_dataset/2012img /home/test/dataset/
fi

if [ "$NAME" = "ai_bench" ]; then
  MOD=`lsmod|grep vast|wc -l`
  if  [ $MOD -lt 1 ]; then
    modprobe drm_kms_helper
    cd /data/driver/ai_new/pcie
    insmod vastai_pci.ko
    cd /home/test/dataset
  fi
else
  echo "no predefined driver, exit!"
  exit
fi

BIN=/data/tools/pmt

mkdir -p $DIR
PCIE=`lspci|grep acc|awk '{print $1}'| tr '\n' ','`
CNT=`lspci|grep acc|wc -l`
CNT1=$((CNT-1))
DEVS=`echo $(seq 0 $CNT1)|tr ' ' ','`
mpstat -P ALL 2                  > $DIR/cpu.csv  2>/dev/null &
sar -d 2                         > $DIR/disk.csv 2>/dev/null &
$BIN/vasmi dmon -d $DEVS -i 0,1  > $DIR/dmon.log 2>/dev/null &
$BIN/mem  --delay=2    --output=$DIR/mem.csv  > /dev/null 2>&1 &
$BIN/pcie --only=$PCIE --output=$DIR/pcie.csv > /dev/null 2>&1 &
#pcm 2 -nc -nsys  -csv=$DIR/cpu.csv  > /dev/null 2>&1 &
#pcm-pcie     -B  -csv=$DIR/pcie.csv > /dev/null 2>&1 &
#pcm-memory 2 -nc -csv=$DIR/mem.csv  > /dev/null  2>&1 &
#./temp.sh 2 $CARD &
#sleep 30
#perf record -F 99 -ag -o $DIR/perf.data -- sleep 30 &

# vaprofiler --video 5
# vaprofiler --bandwidth
# vaprofiler --bandwidth > $DIR/bw.csv 2>&1 &
