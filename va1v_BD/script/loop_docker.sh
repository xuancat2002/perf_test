date
COUNT=`vasmi summary|grep VA1|wc -l`
INDEX=$((COUNT-1))
for i in $(seq 0 $INDEX); do
  echo "video card$i"
  #./start_perf.sh $i        # cpu.csv/pcie.csv/mem.csv
  i_1=$((i-1))
  for j in $(seq 0 $i_1); do
    echo "./docker_video.sh $j > video_card$i.$j.log 2>&1 &"
         ./docker_video.sh $j > video_card$i.$j.log 2>&1 &
  done
  echo "./docker_video.sh $i > video_card$i.$i.log last"
       ./docker_video.sh $i > video_card$i.$i.log 2>&1
  #./stop_perf.sh $i
  sleep 88
done
