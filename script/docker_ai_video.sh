
IDX=${1:-0}
NAME=${2:-ai_bench}
MODE=${3:-deblur}  # deblur/deart

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
EXEC=/opt/vastai/vaststream/release/samples/common/   # run_de.sh
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
  -v /opt/ai_video/:/opt/vastai/vaststream/release/samples/datasets \
  ${AI_ImageID} /bin/bash
sleep 5


docker exec ai_card$IDX bash -c "source /etc/profile; $EXEC/run_de.sh" &
  

#docker exec ai_card$IDX bash -c "source /etc/profile; /opt/vaststream/tool/vaTest -d $DIE1 -b 100 -v 1 -p -1 -i $ITER -j $PERF/$MODEL --batch $BS"
