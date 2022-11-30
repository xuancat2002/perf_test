#!/bin/bash
COUNT=${1:-30}

export LD_LIBRARY_PATH=/opt/vastai/vaststream/3rdparty/libva/lib/dri:/opt/vastai/vaststream/release/vacl/lib:/opt/vastai/vaststream/lib:/opt/vastai/vaststream/ffmpeg/lib:/opt/vastai/vaststream/3rdparty/libva/lib:/opt/vastai/vaststream/3rdparty/libdrm/lib:/opt/vastai/vaststream/tvm/lib:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../../vacl/lib/
#nodes=`ls /dev | grep vacc`
#node=`echo ${nodes} | cut -d " " -f 1`
#node1=`echo ${node: -1}`
#node=`echo ${nodes} | cut -d " " -f 2`
#node2=`echo ${node: -1}`
#json_file=$1
#batchsize=1
#performancefile="./bert_performance.txt"
#/opt/vastai/vaststream/release/samples/05_Bert2Die/vaprofiler -f > $performancefile &

# ./test --help:
#	-h,--help		Show this help message
#	-r,--result		Specify the the result file,default result.txt
#	-b,--buffersize		Specify the the control buffer size, default 84, should > 0

for i in $(seq $COUNT); do
  ./test -j network_die0.json,network_die1.json &

  #./test -d $node1 -p -1 -b 21 --batch $batchsize -j $json_file -v 1 &
  #./test -d $node2 -p -1 -b 21 --batch $batchsize -j $json_file -v 1 &
done

exit
#while true; do
#   processor_num=`ps -aux | grep -w "./test" | grep -v "grep" | awk '{print $2}' | wc -l`
#   if [ $processor_num -eq 0 ];then
#        kill -9 `ps -aux | grep vaprofiler | grep -v "grep" | awk '{print $2}'`
#        break
#   else
#       sleep 5
#   fi
#done
#exit

