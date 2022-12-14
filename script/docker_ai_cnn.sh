
IDX=${1:-0}
NAME=${2:-ai_bench}
MODE=${3:-mobilenet_v1}

ITER=1000000
PERF=/opt/benchmark/conf/mobilenet/perf

AI_ImageID="reg.devops.com/base/benchmark:v1.2.2"
AI_ImageID="8146f5f90780"
DR_NAME=`rpm -qa|grep vastai-pci`
if [ "$DR_NAME" = "vastai-pci-sw-v1-1-alpha-hwtype-2-00.22.09.05-1dkms.x86_64" ]; then
  AI_ImageID="744a372861d7"    # perf test image
  docker_image="/data/driver/bert_2209/bert_test.tar"
elif [ "$DR_NAME" = "vastai-pci-sw-v1-1-alpha-hwtype-2-00.22.09.05-1dkms.x86_64" ]; then
  AI_ImageID="9cd2e9543f99"    # accuracy test image
  docker_image="192.168.20.143:443/vaststream/vaststream_ubuntu18.04:V_202208220913_f579cfa5_sw_v1_1_alpha"
fi

list_image_id=`docker images | grep -i $AI_ImageID|head -1 | awk '{print$3}'`
if [ "$list_image_id" = "$AI_ImageID" ]; then
	echo "-------------Already load--------------------"
else
	echo "-------------Load Docker---------------------"
	#docker pull $docker_image
	docker load -i $docker_image
fi
host_dataset_path=/opt/data
#DATA_SRC=/data/ai_dataset/2012img.tgz
EXEC=/opt/vastai/vaststream/release/samples/05_Bert2Die
NIDX=$((IDX+1))
PCI_N=`lspci|grep accelerators | sed -n ${NIDX}p|awk '{print $1}'`
NODE=`cat /sys/bus/pci/devices/0000:$PCI_N/numa_node`
cgcreate -g cpuset:numanode$NODE
CPUS1=`lscpu|grep node$NODE|awk '{print $4}'`
echo "$CPUS1" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.cpus
echo "$NODE" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.mems


docker run --rm -itd --name ai_card${IDX} \
  --cgroup-parent=numanode${NODE} --net=host \
  --runtime=vastai -e VASTAI_VISIBLE_DEVICES=${IDX} \
   -v /etc/localtime:/etc/localtime -v /opt/data:/opt/data \
  ${AI_ImageID} /bin/bash
sleep 5

#docker run --rm -itd --name bm0 --net=host --runtime=vastai -e VASTAI_VISIBLE_DEVICES=0 -v /etc/localtime:/etc/localtime -v /opt/data:/opt/data reg.devops.com/base/benchmark:v1.2.2
if [ "$NAME" = "model" ]; then
  docker exec ai_card$IDX bash -c "source /etc/profile; cd /opt/benchmark; python3 main.py -m /opt/data/v1.2.2/$MODE"
else
  if [ "$MODE" = "mobilenet_v1" ]; then
    MODEL=mobilenet_v1-keras-keras-fp16-none-224_224-runstream-1.json
    #MODEL=mobilenet_v1-keras-keras-fp16-none-224_224-runstream-8.json
  elif [ "$MODE" = "mobilenet_v2" ]; then
    MODEL=mobilenet_v2-timm-onnx-int8-percentile-224_224-runstream-1.json
    #MODEL=mobilenet_v2-timm-onnx-int8-percentile-224_224-runstream-8.json
  elif [ "$MODE" = "yolov3" ]; then
    MODEL=yolov3-ultralytics-onnx-int8-max-640_640-runstream-pipeline-1.json
  elif [ "$MODE" = "yolov5" ]; then
    MODEL=yolov5l-ultralytics-onnx-int8-max-640_640-runstream-pipeline-1.json
  elif [ "$MODE" = "yolov7" ]; then
    MODEL=yolov7-official-torchscript-int8-percentile-640_640-runstream-pipeline-1.json
  elif [ "$MODE" = "retinaface" ]; then
    MODEL=retinaface_resnet50-official-torchscript-int8-max-640_640-runstream-pipeline-1.json
  elif [ "$MODE" = "resnet" ]; then
    MODEL=resnet50-timm-onnx-fp16-none-224_224-runstream-1.json
    #MODEL=resnet50-timm-onnx-int8-max-224_224-runstream-8.json
  fi
  docker exec ai_card$IDX bash -c "source /etc/profile; cd /opt/benchmark; python3 main.py -m /opt/data/v1.2.2/$MODE"
  sleep 100

  DIE0=$((2*IDX))
  DIE1=$((2*IDX+1))
  docker exec ai_card$IDX bash -c "source /etc/profile; /opt/vaststream/tool/vaTest -d $DIE0 -b 100 -v 1 -p -1 -i $ITER -j $PERF/$MODEL --batch 1" &
  docker exec ai_card$IDX bash -c "source /etc/profile; /opt/vaststream/tool/vaTest -d $DIE1 -b 100 -v 1 -p -1 -i $ITER -j $PERF/$MODEL --batch 1"

fi
