CASE=${1:-1k}      # test case
LOOP=${2:-5}       # loops
date
COUNT=`vasmi summary|grep VA1|wc -l`
INDEX=$((COUNT-1))

NAME=`echo $CASE | awk -F. '{print $1}'`
OPT=`echo $CASE | awk -F. '{print $2}'`
#PARAM=`echo $OPT | sed 's/_/ /g'`

FC=`ls /data|wc -l`
if [ $FC -lt 1 ]; then
  mount -t nfs 192.168.20.2:/nfs/sedata /data
  # cp -r /data/perf_test/ai_dataset/2012img /home/test/dataset/
fi
DC=`docker ps|wc -l`
if [ $DC -gt 1 ]; then
  docker stop `docker ps -aq`
fi

for i in $(seq 0 $INDEX); do
  echo "ai card$i"
  if [ $i -lt $INDEX ]; then
    echo "./docker_resnet50.sh $i $NAME $OPT > resnet_card$i.$CASE.log 2>&1 &"
          ./docker_resnet50.sh $i $NAME $OPT > resnet_card$i.$CASE.log 2>&1 &
  else
    echo "./docker_resnet50.sh $i $NAME $OPT > resnet_card$i.$CASE.log last"
          ./docker_resnet50.sh $i $NAME $OPT > resnet_card$i.$CASE.log 2>&1
  fi
  sleep 1
done

#sleep 30
#for f in `ls resnet_card*log`; do 
#  fps=`cat $f | sed -e 's/\r/\n/g'|grep ^frame= |awk -F= '{print $3}'| awk '{ total += $1; cnt++ } END { print total/cnt }'`
#  echo "$f fps=$fps" >> logs/$CASE/fps.log
#done
