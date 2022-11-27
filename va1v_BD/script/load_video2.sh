CASE=${1:-1}   # test case #
NPROC=${2:-1}  # roads
ITER=${3:-1}   # loops

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
    ["1"]="vidyo1_1280x720_30fps_5M_60400frames.mp4" 
    ["2"]="ParkScene_1920x1080_30fps_loop_8Mx4.mp4"
	["3"]="cdzi-hevc.mp4"  # (not found)
	["4"]="4KH264_5.0Mbps_30fps_8bit_Brazil_5M_3840x2160.mp4"
	["5"]="Winter_Saint_Petersburg_Russia_1500frames_h264_7680x4320.mp4"
)
SOURCE_STREAM="/opt/vastai/vaststream/samples/${VIDEOS[$CASE]}"

#----set parameters-----
# hard encode   / soft encode ?
# common encode / fast encode ?
tune=1
keyint=120
###########################################################
lookahead=20  #0,20
gopsize=0     #0,1
bitrate=2000000  #2000000,4000000,8000000
###########################################################
QUALITYS="gold silver"
CODECS="hevc h264"
#quality=gold  #silver
#codec=hevc    #h264,hevc

renders=`ls /dev/dri | grep render`

for codec in $CODECS; do
  for quality in $QUALITYS; do
	echo "================ codec=$codec quality=$quality"
    for i in $(seq $ITER); do    # loops
      for n in $(seq $NPROC); do    # pid
        for render in $renders; do    # device
            #  -vf 'format=yuv420p,hwupload'
            #  -vast-params lookaheadLength=${lookahead}:miniGopSize=0:tune=${tune}:preset=${quality}_quality:keyint=${keyint} 
            ffmpeg -y -vsync 0 -noautorotate -hwaccel vaapi -hwaccel_output_format vaapi -hwaccel_device:v /dev/dri/${render} -i ${SOURCE_STREAM} -r 30 \
               -c:v ${codec}_vaapi -b:v ${bitrate} -vast-params "tune=1:keyint=120:lookaheadLength=${lookahead}:miniGopSize=${gopsize}:preset=${quality}_quality" \
               "${out_dir}/${render}_${n}_output.${codec}" &
   	    done
      done    # 
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