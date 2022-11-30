#!/bin/bash

CASE=${1:-1k}   # test case #
NPROC=${2:-1}  # roads
ITER=${3:-1}   # loops
MODE=${4:-2pass}  # 1pass/2pass/IPPP
DECODE=${5:-hard}  # soft/hard
FAST=${6:-normal}   # normal/fast

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
#echo "$SCRIPTPATH"
cd $SCRIPTPATH
source /etc/profile

export PATH="$PATH:/opt/vastai/vaststream/ffmpeg/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "
export LD_LIBRARY_PATH=/opt/vastai/vaststream/lib/dri:/opt/vastai/vaststream/lib:/opt/vastai/vaststream/ffmpeg/lib:/opt/vastai/vaststream/tvm/lib

#ulimit -c unlimited
out_dir=output
mkdir -p ${out_dir}

declare -A VIDEOS=( 
    ["720"]="vidyo1_1280x720_30fps_5M_60400frames.mp4"
	["1080"]="cdzi-hevc.mp4"  #1080p
    ["1k"]="ParkScene_1920x1080_30fps_loop_8Mx4.mp4"
	["4k"]="4KH264_5.0Mbps_30fps_8bit_Brazil_5M_3840x2160.mp4"
	["8k"]="Winter_Saint_Petersburg_Russia_1500frames_h264_7680x4320.mp4"
)
SOURCE_STREAM="/opt/vastai/vaststream/samples/${VIDEOS[$CASE]}"
declare -A BITRATES=( 
	["720"]=2000000
    ["1080"]=2000000
    ["1k"]=2000000
	["4k"]=4000000
	["8k"]=8000000
)
bitrate="${BITRATES[$CASE]}"
declare -A FRAMES_FAST=( # soft decode, fast mode    
	["720"]=25000
    ["1080"]=18000 
    ["1k"]=18000
	["4k"]=3000
	["8k"]=1500
)
declare -A FRAMES_NORMAL=( # soft decode, normal mode
	["720"]=9000
    ["1080"]=6000 
    ["1k"]=6000
	["4k"]=1000
	["8k"]=500
)

#-----------------------------minigopsize---lookahead------------#
#1: 1pass lookaheadlength=0 minigopsize=0 
#2: 2pass lookaheadlength=20 minigopsize=0 
#3: IPPP  lookaheadlength=0 minigopsize=1 
if [ "${MODE}" = "1pass" ]; then
	mode=1pass
    lookahead=0
	minigopsize=0
elif [ "${MODE}" = "2pass" ]; then
	mode=2pass
    lookahead=20
    minigopsize=0
elif [ "${MODE}" = "IPPP" ]; then
	mode=IPPP
    lookahead=0
    minigopsize=1
fi

###########################################################
device_id=0
#/opt/vastai/vaststream/tools/vasmi getvideomulticore -d ${device_id} -i 0,1    # get fast mode
if [ "${FAST}" = "fast" ]; then
  #echo "${FAST}"
  frames="${FRAMES_FAST[$CASE]}"
  #frames=25000  #25000 18000 3000 1500     # soft decode, fast   mode
  #/opt/vastai/vaststream/tools/vasmi setvideomulticore 1 -d ${device_id} -i 0,1  # set fast mode
elif [ "${FAST}" = "normal" ]; then
  #echo "${FAST}"
  frames="${FRAMES_NORMAL[$CASE]}"
  #frames=9000   #9000   6000 1000  500     # soft decode, normal mode
  #/opt/vastai/vaststream/tools/vasmi setvideomulticore 0 -d ${device_id} -i 0,1  # set normal mode(default)
fi
sleep 10

tune=1
intraqpoffset=-2
QUALITYS="gold silver"
CODECS="hevc h264"
renders=`ls /dev/dri | grep render`

for codec in $CODECS; do
  for quality in $QUALITYS; do
	echo "================ codec=$codec quality=$quality"
    for i in $(seq $ITER); do    # loops
      for n in $(seq $NPROC); do    # pid
        for render in $renders; do    # device
          # soft decode : 
		  if [ "${DECODE}" = "soft" ]; then
			keyint=120   # soft decode
			ffmpeg -y -vsync 0 -i ${SOURCE_STREAM} -vaapi_device /dev/dri/${render} -vf 'format=yuv420p,hwupload' \
               -c:v ${codec}_vaapi -vframes ${frames} -an -b:v ${bitrate} \
               -vast-params "tune=${tune}:lookaheadLength=${lookahead}:miniGopSize=${gopsize}:preset=${preset}_quality:keyint=${keyint}" \
               "${out_dir}/${render}_${n}_output.${codec}" &
		  elif [ "${DECODE}" = "hard" ]; then
			keyint=60    # hard decode
			# hard decode : -vsync 0 -noautorotate
		    ffmpeg -y -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/${render} \
		       -i ${SOURCE_STREAM} -r 30 -c:v ${codec}_vaapi -b:v ${bitrate} \
		       -vast-params "tune=${tune}:vbvBufSize=$(($bitrate/1000)):vbvMaxRate=$(($bitrate*3/2500)):keyint=${keyint}:miniGopSize=${minigopsize}:lookaheadLength=${lookahead}:intraQpOffset=${intraqpoffset}:preset=${preset}_quality" \
		       "${out_dir}/${render}_${n}_output.${codec}" &
		  fi
   	    done    # device
      done    # pid
      wait
	  sleep 60
    done    # loops
  done    # quality
done    # codec

###########################################################################################################################################################
#ffmpeg -y -vsync 0 -noautorotate -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/${render} -i ${SOURCE_STREAM} \
#   -r 30 -c:v ${codec}_vaapi -b:v ${bitrate} \
#   -vast-params "keyint=120:intraQpOffset=-2:vbvBufSize=5000:vbvMaxRate=6000" \
#   -vast-params "tune=${tune}:vbvBufSize=$(($bitrate/1000)):vbvMaxRate=$(($bitrate*3/2500)):keyint=${keyint}:miniGopSize=${minigopsize}:lookaheadLength=${lookahead}:intraQpOffset=-2:preset=${preset}_quality" \
#   "${out_dir}/${render}_${n}_output.${codec} &

# software decode
#ffmpeg -vsync 0 -i input.mp4 -vaapi_device /dev/dri/renderD129 -vf 'format=yuv420p,hwupload' \
# -y -c:v hevc_vaapi -vast-params lookaheadLength=20:miniGopSize=0:tune=1:preset=gold_quality \
# out.hevc

# hardware decode
#ffmpeg -y -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/\
# renderD128 -r 30 -i input.mp4 -r 30 -c:v h264_vaapi -b:v 2000000 -vast-params \
# "tune=1:vbvBufSize=2000:vbvMaxRate=2400:keyint=60:miniGopSize=0:lookaheadLength=0:\
# intraQpOffset=-2:preset=gold_quality" output.h264
