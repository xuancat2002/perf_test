CASE=${1:-1k}      # test case
date
COUNT=`vasmi summary|grep VA1|wc -l`
INDEX=$((COUNT-1))
PARAM=`echo $CASE | sed 's/_/ /g'`
docker stop `docker ps -aq`
for i in $(seq 0 $INDEX); do
  echo "video card$i"
  #./start_perf.sh $i        # cpu.csv/pcie.csv/mem.csv
  if [ $i -lt $INDEX ]; then
    echo "./docker_video.sh $i $PARAM > video_card$i.$CASE.log 2>&1 &"
         ./docker_video.sh $i $PARAM > video_card$i.$CASE.log 2>&1 &
  else
    echo "./docker_video.sh $i $PARAM > video_card$i.$CASE.log last"
         ./docker_video.sh $i $PARAM > video_card$i.$CASE.log 2>&1
  fi
  #./stop_perf.sh $i
  sleep 1
done
