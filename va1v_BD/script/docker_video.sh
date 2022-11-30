# yum install -y libcgroup libcgroup-tools
#docker load -i docker_NPI_v1.4.tar

IDX=${1:-0}
CASE=${2:-1k}
#File="ParkScene_1920x1080_30fps_8M.mp4"
#URL="http://qa.vastai.com/datasets/$File"
DR_NAME=`rpm -qa|grep vastai-pci`
if [ "$DR_NAME" = "vastai-pci-server-adaption-va1-v-0622-hwtype-1-00.22.06.28-1dkms.x86_64" ]; then
  ImageID=2c783a6d863a    # old driver
elif [ "$DR_NAME" = "vastai-pci-sw-v1-3-vd-hwtype-1-00.22.11.23-1dkms.x86_64" ]; then
  ImageID=9f8d0ce57641    # new driver: sw_v1_3_vd
fi
host_dataset_path=/home/test/dataset
NIDX=$((IDX+1))
PCI_N=`lspci|grep accelerators | sed -n ${NIDX}p|awk '{print $1}'`
NODE=`cat /sys/bus/pci/devices/0000:$PCI_N/numa_node`
cgcreate -g cpuset:numanode$NODE
CPUS1=`lscpu|grep node$NODE|awk '{print $4}'`
echo "$CPUS1" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.cpus
echo "$NODE" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.mems
#echo "docker run --rm -it --entrypoint=$SH --name card$IDX  --cgroup-parent=numanode$NODE --privileged --runtime=vastai -e VASTAI_VISIBLE_DEVICES=$IDX -v ${host_dataset_path}:/opt/vastai/vaststream/samples/dataset   ${ImageID}"
#DIR=/opt/vastai/vaststream/samples/dataset/
DIR=/opt/vastai/vaststream/samples/
OUT=${host_dataset_path}/output$IDX
mkdir -p ${OUT}
rm -rf ${OUT}/*

docker stop video_card${IDX}
sleep 2
docker run --rm -itd --name video_card${IDX}  \
  --cgroup-parent=numanode${NODE} \
  --runtime=vastai -e VASTAI_VISIBLE_DEVICES=${IDX} \
  -v ${OUT}/output:${DIR}/output \
  ${ImageID} /bin/bash
sleep 5

if [ $CASE -eq 0 ]; then
  docker cp $host_dataset_path/ParkScene_1920x1080_30fps_8M.mp4 video_card${IDX}:$DIR
  docker cp $host_dataset_path/load_video.sh video_card${IDX}:$DIR
  docker exec video_card$IDX bash -c "source /etc/profile; sh $DIR/load_video.sh 1"
else
  declare -A VIDEOS=( 
    ["720"]="vidyo1_1280x720_30fps_5M_60400frames.mp4"
  	["1080"]="cdzi-hevc.mp4"  #1080p
    ["1k"]="ParkScene_1920x1080_30fps_loop_8Mx4.mp4"
  	["4k"]="4KH264_5.0Mbps_30fps_8bit_Brazil_5M_3840x2160.mp4"
  	["8k"]="Winter_Saint_Petersburg_Russia_1500frames_h264_7680x4320.mp4"
  )
  DIR=/opt/vastai/vaststream/samples/
  docker cp /data/video_data/${VIDEOS[$CASE]} video_card${IDX}:$DIR
  docker cp $host_dataset_path/load_video2.sh video_card${IDX}:$DIR
  # video:    720/1080/1k/4k/8k
  # quality:  gold/silver
  # test:     1pass/2pass/IPPP
  # decode:   soft/hard
  # mode:     normal/fast
  docker exec video_card$IDX bash -c "sh $DIR/load_video2.sh $CASE gold 2pass hard normal"
fi

#docker exec card$IDX bash -c 'source /etc/profile && sh /opt/vastai/vaststream/samples/script/video_press.sh'
#BIN="export PATH=$PATH:/opt/vastai/vaststream/ffmpeg/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "
#LIB="export LD_LIBRARY_PATH=/opt/vastai/vaststream/lib/dri:/opt/vastai/vaststream/lib:/opt/vastai/vaststream/ffmpeg/lib:/opt/vastai/vaststream/tvm/lib"
#PID=`docker inspect --format {{.State.Pid}} card$IDX`
#nsenter --target $PID --mount --uts --ipc --net --pid<<EOF
#$BIN;$LIB;
#cd $DIR; 
#./load_video.sh 1  # loops
#EOF
