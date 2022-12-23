CASE=${1:-ai_video.deblur_1}      # test case

date
echo "entering benchmark"

NAME=`echo $CASE | awk -F. '{print $1}'`
OPT=`echo $CASE | awk -F. '{print $2}'`
PARAM=`echo $OPT | sed 's/_/ /g'`

FC=`ls /data|wc -l`
if [ $FC -lt 1 ]; then
  mount -t nfs 192.168.20.2:/nfs/sedata /data
  # cp -r /data/perf_test/ai_dataset/2012img /home/test/dataset/
fi

DATA=/opt/ai_video_tmp
TMP=`mount |grep tmpfs|grep $DATA|wc -l`
if [ $TMP -gt 0 ]; then
   echo tmpfs on $DATA
else
   mount -t tmpfs -o size=100g tempfs $DATA
   #cp -r /opt/ai_video/deart_data      /opt/ai_video_tmp/   # 2s
   #cp -r /opt/ai_video/deblur_datasets /opt/ai_video_tmp/   # 100s
   cp -r /data/ai_video/deart_data      /opt/ai_video_tmp/
   cp -r /data/ai_video/deblur_datasets /opt/ai_video_tmp/
fi

MOD=`lsmod|grep vast|wc -l`
if  [ $MOD -lt 1 ]; then
  rpm -ivh /data/ai_video/vastai-pci-d2-0-v1-1-a1-1-ks-facesr-hwtype-0_00.22.12.15_x86_64.rpm
fi

COUNT=`/data/tools/pmt/vasmi summary|grep VA1|wc -l`
INDEX=$((COUNT-1))

DC=`docker ps|wc -l`
if [ $DC -gt 1 ]; then
  docker stop `docker ps -aq`
fi

date 
echo "starting benchmark"

for i in $(seq 0 $INDEX); do
    echo "ai card$i"
    echo "./docker_ai_video.sh $i $NAME $PARAM > av_card$i.$CASE.log 2>&1 &"
          ./docker_ai_video.sh $i $NAME $PARAM > av_card$i.$CASE.log 2>&1 &
  sleep 1
done

sleep 30

while true; do
   processor_num=`ps -aux | grep -w test | grep -v grep |grep -v loop_docker_ai_video.sh | awk '{print $2}' | wc -l`
   if [ $processor_num -eq 0 ];then
        sleep 35
        processor_num=`ps -aux | grep -w test | grep -v grep |grep -v loop_docker_ai_video.sh | awk '{print $2}' | wc -l`
        if [ $processor_num -eq 0 ];then
            killall vaprofiler vasmi mpstat pcie mem sar 2>/dev/null
            break
        fi
   else
       sleep 10
   fi
done
