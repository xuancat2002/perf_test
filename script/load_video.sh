#!/bin/bash
COUNT=${1:-3}
MODE=${2:-transcode}  # transcode/decode/encode

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo "$SCRIPTPATH"
cd $SCRIPTPATH

source /etc/profile
export PATH="$PATH:/opt/vastai/vaststream/ffmpeg/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "
export LD_LIBRARY_PATH=/opt/vastai/vaststream/lib/dri:/opt/vastai/vaststream/lib:/opt/vastai/vaststream/ffmpeg/lib:/opt/vastai/vaststream/tvm/lib

dev_inf=$(ls /dev/dri/ | grep renderD | cut -d " " -f 1)
node1=$(echo ${dev_inf} | cut -d " " -f 1 | cut -d "D" -f 2)
node2=$(echo ${dev_inf} | cut -d " " -f 2 | cut -d "D" -f 2)
echo "node1:$node1----node2:$node2-----"
# ffmpeg -y -noautorotate -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/renderD128 -i /opt/vastai/vaststream/samples/ParkScene_1920x1080_30fps_8M.mp4 -r 30 -c:v hevc_vaapi -b:v 5000000 -vast-params "keyint=120:intraQpOffset=-2:vbvBufSize=5000:vbvMaxRate=6000" "results_128_129/SV100_HEVC/ParkScene_1920x1080_30fps_8M_0.hevc"
if [ "$MODE"="transcode" ]; then
  for i in $(seq $COUNT); do
    foldName=results_${node1}_${node2}
    vid_file=ParkScene_1920x1080_30fps_8M.mp4
    video_path_name=/opt/vastai/vaststream/samples/${vid_file}
    echo "h265$i" > loop.txt
    mkdir -p ${foldName}/SV100_HEVC
    for num in $(seq 0 23); do
        ffmpeg -y -vsync 0 -noautorotate -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/renderD${node1} -i ${video_path_name} -r 30 -c:v hevc_vaapi -b:v 5000000 -vast-params "keyint=120:intraQpOffset=-2:vbvBufSize=5000:vbvMaxRate=6000" "${foldName}/SV100_HEVC/ParkScene_1920x1080_30fps_8M_$num.hevc" &
        ffmpeg -y -vsync 0 -noautorotate -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/renderD${node2} -i ${video_path_name} -r 30 -c:v hevc_vaapi -b:v 5000000 -vast-params "keyint=120:intraQpOffset=-2:vbvBufSize=5000:vbvMaxRate=6000" "${foldName}/SV100_HEVC/ParkScene_1920x1080_30fps_8M_$(($num + 24)).hevc" &
    done
    wait
    sync
    rm -rf ${foldName}/SV100_HEVC

    mkdir -p ${foldName}/SV100_H264
	echo "h264$i" > loop.txt
    for num in $(seq 0 23); do
        ffmpeg -y -vsync 0 -noautorotate -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/renderD${node1} -i ${video_path_name} -r 30 -c:v h264_vaapi -b:v 2500000 -vast-params "keyint=120:intraQpOffset=-2:vbvBufSize=2500:vbvMaxRate=3000" "${foldName}/SV100_H264/ParkScene_1920x1080_30fps_8M_$num.h264" &
        ffmpeg -y -vsync 0 -noautorotate -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/renderD${node2} -i ${video_path_name} -r 30 -c:v h264_vaapi -b:v 2500000 -vast-params "keyint=120:intraQpOffset=-2:vbvBufSize=2500:vbvMaxRate=3000" "${foldName}/SV100_H264/ParkScene_1920x1080_30fps_8M_$(($num + 24)).h264" &
    done
    wait
    sync
    rm -rf ${foldName}/SV100_H264
    cat /dev/null > nohup.out
  done
elif [ "$MODE"="decode" ]; then
  for i in $(seq $COUNT); do
	  cd /LH/RUN/vaststream-1.1.0/common
	  ./decode.sh
	  wait
  done
fi