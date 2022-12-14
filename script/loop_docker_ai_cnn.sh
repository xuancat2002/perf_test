CASE=${1:-mobilenet_v1.100000}      # test case

date
echo "entering benchmark"

NAME=`echo $CASE | awk -F. '{print $1}'`
OPT=`echo $CASE | awk -F. '{print $2}'`
#PARAM=`echo $OPT | sed 's/_/ /g'`

FC=`ls /data|wc -l`
if [ $FC -lt 1 ]; then
  mount -t nfs 192.168.20.2:/nfs/sedata /data
  # cp -r /data/perf_test/ai_dataset/2012img /home/test/dataset/
fi

MOD=`lsmod|grep vast|wc -l`
if  [ $MOD -lt 1 ]; then
  cd /data/driver/ai_new/pcie
  modprobe drm_kms_helper
  insmod vastai_pci.ko
  cd /home/test/dataset
fi

COUNT=`vasmi summary|grep VA1|wc -l`
INDEX=$((COUNT-1))

DC=`docker ps|wc -l`
if [ $DC -gt 1 ]; then
  docker stop `docker ps -aq`
fi

#./docker_ai_cnn.sh 0 model $OPT > cnn_model.$CASE.log 
date 
echo "starting benchmark"

for i in $(seq 0 $INDEX); do
    echo "ai card$i"
    echo "./docker_ai_cnn.sh $i $NAME $OPT > cnn_card$i.$CASE.log 2>&1 &"
          ./docker_ai_cnn.sh $i $NAME $OPT > cnn_card$i.$CASE.log 2>&1 &
  sleep 1
done

sleep 30

while true; do
   processor_num=`ps -aux | grep -w "main.py" | grep -v "grep" | awk '{print $2}' | wc -l`
   if [ $processor_num -eq 0 ];then
        break
   else
       sleep 10
   fi
done

sleep 120

while true; do
   processor_num=`ps -aux | grep -w "vaTest" | grep -v "grep" | awk '{print $2}' | wc -l`
   if [ $processor_num -eq 0 ];then
        sleep 10
        killall vaprofiler vasmi mpstat pcie mem sar AMDuProfPcm 2>/dev/null
        break
   else
       sleep 10
   fi
done
