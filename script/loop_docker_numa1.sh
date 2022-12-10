CASE=${1:-720_bronze_IPPP_hard_normal_hevc}
date
COUNT=`vasmi summary|grep VA1|wc -l`
PARAM=`echo $CASE | sed 's/_/ /g'`

DC=`docker ps|wc -l`
if [ $DC -gt 1 ]; then
  docker stop `docker ps -aq`
fi

   echo "video card2"
   i=2
   echo "./docker_video.sh $i $PARAM > video_card$i.$CASE.log 2>&1 &"
         ./docker_video.sh $i $PARAM > video_card$i.$CASE.log 2>&1 &
   i=3
   echo "./docker_video.sh $i $PARAM > video_card$i.$CASE.log last"
         ./docker_video.sh $i $PARAM > video_card$i.$CASE.log 2>&1

sleep 30
cat  video_card2.$CASE.log | sed -e 's/\r/\n/g'|grep ^frame= |awk -F= '{print $3}'| awk '{ total += $1; count++ } END { print total/count }' > frame2.log
cat  video_card3.$CASE.log | sed -e 's/\r/\n/g'|grep ^frame= |awk -F= '{print $3}'| awk '{ total += $1; count++ } END { print total/count }' > frame3.log
no_tmpfs: fps=32.0148
