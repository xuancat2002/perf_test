#!/bin/bash 
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

CARD=${1:-ai_bench.yolov7}
DIR="logs/$CARD"

killall vaprofiler vasmi mpstat pcie mem sar AMDuProfPcm >/dev/null 2>&1 
sleep 5

NAME=`echo $CARD | awk -F. '{print $1}'`

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
  MOD=`lsmod|grep vast|wc -l`
  if  [ $MOD -lt 1 ]; then
    echo "no predefined driver for $NAME, exit!"
    exit
  fi
fi

BIN=/data/tools/pmt

mkdir -p $DIR
PCIE=`lspci|grep acc|awk '{print $1}'| tr '\n' ','`
CNT=`lspci|grep acc|wc -l`
CNT1=$((CNT-1))
DEVS=`echo $(seq 0 $CNT1)|tr ' ' ','`
mpstat -P ALL 2                  > $DIR/cpu.csv  2>/dev/null &
sar -d 2                         > $DIR/disk.csv 2>/dev/null &
$BIN/vasmi dmon -d $DEVS -i 0,1  > $DIR/va_dmon.log 2>/dev/null &
$BIN/vaprofiler --utilize        > $DIR/va_util.log 2>&1 &
#$BIN/vaprofiler --bandwidth     > $DIR/va_bw.log 2>&1 &

AMDCPU=`lscpu|grep "^Model name"|grep AMD|wc -l`
ARMCPU=`lscpu|grep "Architecture"|grep aarch64|wc -l`
if [ $AMDCPU -gt 0 ]; then
  echo "AMD uProf"
  $BIN/AMDuProf/bin/AMDuProfPcm -m memory -d 3600 -a -o $DIR/amd_mem.csv  > /dev/null 2>&1 &
  $BIN/AMDuProf/bin/AMDuProfPcm -m pcie   -d 3600 -a -o $DIR/amd_pcie.csv > /dev/null 2>&1 &

elif [ "$ARMCPU" -gt 0 ]; then
  echo "no mem/pcie tools for ARM"
else
  $BIN/mem  --delay=2    --output=$DIR/mem.csv  > /dev/null 2>&1 &
  $BIN/pcie --only=$PCIE --output=$DIR/pcie.csv > /dev/null 2>&1 &
fi

#./temp.sh 2 $CARD &
#sleep 30
#perf record -F 99 -ag -o $DIR/perf.data -- sleep 30 &
# vaprofiler --video 5
# vaprofiler --bandwidth
# vaprofiler --bandwidth > $DIR/bw.csv 2>&1 &
