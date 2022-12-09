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
