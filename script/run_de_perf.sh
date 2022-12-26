#! /bin/bash
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../../vacl/lib/
nodes=`ls /dev | grep vacc`
node=`echo ${nodes} | cut -d " " -f 1`
node1=`echo ${node: -1}`
node=`echo ${nodes} | cut -d " " -f 2`
node2=`echo ${node: -1}`
json_file=$1
batchsize=$2
#performancefile=${3:-profiler.log}
#devID=`ls /dev | grep kchar | cut -d ':' -f 2`
#/opt/vastai/vaststream/release/samples/common/vaprofiler -f -d ${devID} > $performancefile &
for i in {0..4}; do
	if [ "`echo $json_file | grep de`" != "" ]; then 
	        json_name=`echo $(basename $json_file .json)`
	        height=`echo $json_name | cut -d '_' -f 2`
        	width=`echo $json_name | cut -d '_' -f 3`
		if (( $height < 536 )) || (( $width < 536 )) ; then			
	                ./test -d $node1 -b 21 -p 1 --batch $batchsize -j $json_file -v 0  &
	                ./test -d $node2 -b 21 -p 1 --batch $batchsize -j $json_file -v 0  &
		else
                        ./test -d $node1 -b 21  --batch $batchsize -j $json_file -v 0  &
                        ./test -d $node2 -b 21  --batch $batchsize -j $json_file -v 0  &			
		fi
        else
                ./test -d $node1 -b 21 --batch $batchsize -j $json_file -v 0  --verify yes & 
                ./test -d $node2 -b 21 --batch $batchsize -j $json_file -v 0  --verify yes &
        fi                
done
while true
do
   processor_num=`ps -aux | grep "./test" | grep -v "grep" | awk '{print $2}' | wc -l`
   if [ $processor_num -eq 0 ];then
        kill -9 `ps -aux | grep vaprofiler | grep -v "grep" | awk '{print $2}'`
        break
   else
       sleep 5
   fi
done
exit
