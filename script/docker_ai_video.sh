
IDX=${1:-0}
NAME=${2:-ai_video}
MODE=${3:-deblur}  # deblur/deart/all
MEM=${4:-mem}
LOOP=${5:-1}

AI_ImageID="96f8d416379f"
DR_NAME=`rpm -qa|grep vastai-pci`
if [ "$DR_NAME" = "vastai-pci-sw-v1-1-alpha-hwtype-2-00.22.09.05-1dkms.x86_64" ]; then
  AI_ImageID="96f8d416379f"
  docker_image="/data/ai_video/kuaishou.tar"
elif [ "$DR_NAME" = "vastai-pci-sw-v1-1-alpha-hwtype-2-00.22.09.05-1dkms.x86_64" ]; then
  AI_ImageID="96f8d416379f"
  docker_image=""
fi

list_image_id=`docker images | grep -i $AI_ImageID|head -1 | awk '{print$3}'`
if [ "$list_image_id" = "$AI_ImageID" ]; then
	echo "-------------Already load--------------------"
else
	echo "-------------Load Docker---------------------"
	#docker pull $docker_image
	docker load -i $docker_image
fi
host_dataset_path=/opt/ai_video/
host_tmpfs=/home/test/dataset/tmp_$IDX
TMP=`mount |grep tmpfs|grep $host_tmpfs |wc -l`
if [ $TMP -gt 0 ]; then
   echo tmpfs on $host_tmpfs
else
   mkdir -p $host_tmpfs
   mount -t tmpfs -o size=20g tempfs $host_tmpfs
fi
EXEC=/opt/vastai/vaststream/release/samples/common/   # run_de.sh
EXEC_TMP=/opt/vastai/vaststream/release/samples/tmp/   # run_de.sh
DATA=/opt/vastai/vaststream/release/samples/datasets
NIDX=$((IDX+1))
PCI_N=`lspci|grep accelerators | sed -n ${NIDX}p|awk '{print $1}'`
NODE=`cat /sys/bus/pci/devices/0000:$PCI_N/numa_node`
cgcreate -g cpuset:numanode$NODE
CPUS1=`lscpu|grep node$NODE|awk '{print $4}'`
echo "$CPUS1" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.cpus
echo "$NODE" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.mems

docker run --rm -itd --name ai_card${IDX} \
  --cgroup-parent=numanode${NODE} \
  --runtime=vastai -e VASTAI_VISIBLE_DEVICES=${IDX} \
  -v $host_dataset_path:$DATA \
  -v $host_tmpfs:$EXEC_TMP \
  ${AI_ImageID} /bin/bash

sleep 5

if [ "$MEM" = "mem" ]; then
  docker exec ai_card$IDX bash -c "cp -r $EXEC/* $EXEC_TMP"
  EXEC=$EXEC_TMP
fi
docker cp run_de.sh ai_card$IDX:$EXEC
docker cp run_de_perf.sh ai_card$IDX:$EXEC
docker exec ai_card$IDX bash -c "source /etc/profile; cd $EXEC; ./run_de.sh $LOOP $MODE n" &
