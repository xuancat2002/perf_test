CASE=${1:-deblur.1}      # test case

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

TMP=`mount |grep tmpfs|grep $OUT|wc -l`
if [ $TMP -gt 0 ]; then
   echo tmpfs on $OUT
else
   #mount -t tmpfs -o size=100g tempfs $OUT
   echo "mount tmpfs"
fi

MOD=`lsmod|grep vast|wc -l`
if  [ $MOD -lt 1 ]; then
  rpm -ivh /data/ai_video/vastai-pci-d2-0-v1-1-a1-1-ks-facesr-hwtype-0_00.22.12.15_x86_64.rpm
fi

COUNT=`vasmi summary|grep VA1|wc -l`
INDEX=$((COUNT-1))

DC=`docker ps|wc -l`
if [ $DC -gt 1 ]; then
  docker stop `docker ps -aq`
fi

date 
echo "starting benchmark"

for i in $(seq 0 $INDEX); do
    echo "ai card$i"
    echo "./docker_ai_video.sh $i $NAME $OPT > av_card$i.$CASE.log 2>&1 &"
          ./docker_ai_video.sh $i $NAME $OPT > av_card$i.$CASE.log 2>&1 &
  sleep 1
done

sleep 30

while true; do
   processor_num=`ps -aux | grep -w test | grep -v "grep" | awk '{print $2}' | wc -l`
   if [ $processor_num -eq 0 ];then
        sleep 10
        killall vaprofiler vasmi mpstat pcie mem sar 2>/dev/null
        break
   else
       sleep 10
   fi
done
