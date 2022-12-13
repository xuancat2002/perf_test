# yum install -y libcgroup libcgroup-tools
#rpm -q --whatprovides /usr/bin/cgcreate
#libcgroup-tools-0.41-19.el8.x86_64

IDX=${1:-0}
NAME=${2:-model}
LOOP=${3:-5}
#AI_ImageID=5ae2fba24458
AI_ImageID="2c783a6d863a"
DR_NAME=`rpm -qa|grep vastai-pci`
if [ "$DR_NAME" = "vastai-pci-server-adaption-va1-v-0622-hwtype-1-00.22.06.28-1dkms.x86_64" ]; then
  AI_ImageID="2c783a6d863a"    # old driver: 22.06.28
  docker_image=/data/driver/resnet50_old/docker_NPI_v1.4.tar
elif [ "$DR_NAME" = "vastai-pci-sw-v1-3-vd-hwtype-1-00.22.11.23-1dkms.x86_64" ]; then
  AI_ImageID="2c783a6d863a"    # new driver: 22.11.23
  docker_image=/data/driver/resnet50_old/docker_NPI_v1.4.tar
fi
host_dataset_path=/home/test/dataset
#DATA_SRC=/data/perf_test/ai_dataset/2012img.tgz
DATA=/home/test/dataset
#DATA_IN=/LH/RUN/vaststream-1.1.0/common/datasets
DATA_IN=/opt/vastai/vaststream/release/samples/datasets
EXEC=/opt/vastai/vaststream/release/samples/01_Resnet50
NIDX=$((IDX+1))
PCI_N=`lspci|grep accelerators | sed -n ${NIDX}p|awk '{print $1}'`
NODE=`cat /sys/bus/pci/devices/0000:$PCI_N/numa_node`
cgcreate -g cpuset:numanode$NODE
CPUS1=`lscpu|grep node$NODE|awk '{print $4}'`
echo "$CPUS1" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.cpus
echo "$NODE" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.mems

list_image_id=`docker images | grep -i $AI_ImageID | awk '{print$3}'`
if [ "$list_image_id" = "$AI_ImageID" ]; then
	echo "-------------Already load--------------------"
else
	echo "-------------Load Docker---------------------"
	docker load < $docker_image
fi

#docker run -it --name sit-1011-0 --runtime=vastai -e VASTAI_VISIBLE_DEVICES=0 -v /data/qa-data/test-result/ai/datasets/:/opt/vastai/vaststream/release/samples/datasets/ cb1b402e82cd /bin/bash
docker run --rm -itd --name ai_card${IDX} \
  --cgroup-parent=numanode${NODE} \
  --runtime=vastai -e VASTAI_VISIBLE_DEVICES=${IDX} \
  -v ${host_dataset_path}:${DATA_IN} \
  ${AI_ImageID} /bin/bash
sleep 5

docker exec ai_card$IDX bash -c "source /etc/profile && cd $EXEC; ./performance_s.sh $LOOP"
#DIR=/LH/RUN/40decode
#docker exec ai_card$IDX bash -c "source /etc/profile && nohup $DIR/run_40decode.sh &"  # todo add loop number
# nohup ./run_40decode.sh &


#docker_path=/home/RUN/SDK1_1_10091019.tar
#docker_imagesID=1c31897cb2df
#datasets_path=/home/RUN/datasets
#driver_path=/home/RUN/pcie_fb9a7a
#docker_ai_path=/LH/RUN/vaststream-1.1.0/common
#dataset_path=/LH/RUN/vaststream-1.1.0/common/datasets
#docker_decode_path=/LH/RUN/40decode
#service docker start
#a=`docker images | grep -i 1c31897cb2df | awk '{print$3}'`
#b=`ls /dev/kchar* | awk '{print$NF}' | cut -d ":" -f 2`
#c=`docker ps -a | grep -i "/bin/bash" | awk '{print$1}' | tr -s '\n' ' '`
#d=`docker ps -a | wc -l `
#if [ "$d" -ne "1" ]
#then
#	docker stop $c
#	docker rm $c
#fi
#if test -e /dev/kchar:0
#then
#        echo "------------Driber Already insmod----------"
#else
#        insmod ${driver_path}/vastai_pci.ko
#fi
#b=`ls /dev/kchar* | awk '{print$NF}' | cut -d ":" -f 2`
#if [ "$a" = "1c31897cb2df" ]   
#then
#	echo "-------------Already load--------------------"
#else
#	echo "-------------Load Docker---------------------"
#	docker load < $docker_path
#fi

#for x in $b
#do#
#	./docker.exp $x ${datasets_path} ${docker_imagesID}
#	sleep 4
#	e=`docker ps -a | grep -i "/bin/bash" | sed -n '1p' | awk '{print$1}'`
#	docker rename $e VE1_card$x
#	docker start $e
#	./AI_Decode.exp $e ${docker_ai_path} ${docker_decode_path}
#done
