# yum install -y libcgroup libcgroup-tools
#rpm -q --whatprovides /usr/bin/cgcreate
#libcgroup-tools-0.41-19.el8.x86_64

IDX=${1:-0}
#AI_ImageID=5ae2fba24458
DR_NAME=`rpm -qa|grep vastai-pci`
if [ "$DR_NAME" = "vastai-pci-sw-v1-1-alpha-hwtype-2-00.22.09.05-1dkms.x86_64" ]; then
  AI_ImageID="744a372861d7"    # perf test image
  docker_image="/data/driver/bert_2209/bert_test.tar"
elif [ "$DR_NAME" = "vastai-pci-sw-v1-1-alpha-hwtype-2-00.22.09.05-1dkms.x86_64" ]; then
  AI_ImageID="9cd2e9543f99"    # accuracy test image
  docker_image="192.168.20.143:443/vaststream/vaststream_ubuntu18.04:V_202208220913_f579cfa5_sw_v1_1_alpha"
fi

list_image_id=`docker images | grep -i $AI_ImageID | awk '{print$3}'`
if [ "$list_image_id" = "$AI_ImageID" ]; then
	echo "-------------Already load--------------------"
else
	echo "-------------Load Docker---------------------"
	#docker pull $docker_image
	docker load -i $docker_image
fi
host_dataset_path=/home/test/dataset
#DATA_SRC=/data/perf_test/ai_dataset/2012img.tgz
DATA=/home/test/dataset
#DATA_IN=/LH/RUN/vaststream-1.1.0/common/datasets
MODEL=/opt/vastai/vaststream/release/samples/models/
EXEC=/opt/vastai/vaststream/release/samples/05_Bert2Die
NIDX=$((IDX+1))
PCI_N=`lspci|grep accelerators | sed -n ${NIDX}p|awk '{print $1}'`
NODE=`cat /sys/bus/pci/devices/0000:$PCI_N/numa_node`
cgcreate -g cpuset:numanode$NODE
CPUS1=`lscpu|grep node$NODE|awk '{print $4}'`
echo "$CPUS1" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.cpus
echo "$NODE" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.mems

#   -v ${host_dataset_path}:${DATA_IN}
# start
docker run --rm -itd --name ai_card${IDX} \
  --cgroup-parent=numanode${NODE} \
  --runtime=vastai -e VASTAI_VISIBLE_DEVICES=${IDX} \
  ${AI_ImageID} /bin/bash
sleep 5

docker cp $host_dataset_path/load_bert.sh ai_card${IDX}:$EXEC
#docker exec ai_card$IDX bash -c "source /etc/profile; cd $EXEC; ./load_bert.sh 30"
docker exec ai_card$IDX bash -c "source /etc/profile && cd $EXEC; ./bert_performance.sh 10"
#docker exec ai_card$IDX bash -c "source /etc/profile && cd $EXEC; make; ./test -j network_die0.json,network_die1.json"
