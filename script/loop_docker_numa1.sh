CASE=${1:-v_baidu_720_bronze_IPPP_hard_normal_hevc}
date
COUNT=`vasmi summary|grep VA1|wc -l`
NAME=`echo $CASE | awk -F. '{print $1}'`
OPT=`echo $CASE | awk -F. '{print $2}'`
PARAM=`echo $OPT | sed 's/_/ /g'`

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
FPS=logs/$CASE/fps.log
echo "" > $FPS
for f in `ls video_card*log`; do 
  fps=`cat $f | sed -e 's/\r/\n/g'|grep ^frame= |awk -F= '{print $3}'| awk '{ total += $1; cnt++ } END { print total/cnt }'`
  echo "$f fps=$fps" >> $FPS
done

#no_tmpfs: fps=32.0482 31.935
#   tmpfs: fps=32.039  31.9363
