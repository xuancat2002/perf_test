PIDS=`ps -ef|grep vastai_dma_wq|grep -v "\[vastai_dma_wq\]"|grep -v grep|awk '{print $2}'`
#PIDS=`ps -ef|grep vastai_dma_wq|grep -v grep|awk '{print $2}'`
CPU=`ps -mo pid,tid,%cpu,psr -p $PIDS|grep "^     "|awk {'print $2","$NF'}`
#CPU=`ps -mo pid,tid,%cpu,psr -p $PIDS|grep "^     "|awk '{print $NF}'`
NUMA0=`numactl -H|grep cpus|head -1|awk -F: '{print $2}'`
NUMA1=`numactl -H|grep cpus|tail -1|awk -F: '{print $2}'`

declare -A numa_map

for c in $NUMA0; do
  numa_map[$c]="0"
done
for c in $NUMA1; do
  numa_map[$c]="1"
done

echo -e "PID \tCPU \tNUMA"
for pid_cpu in $CPU; do 
  IFS=',' read -a myarray <<< "$pid_cpu"
  pid=${myarray[0]}
  cpu=${myarray[1]}
  echo -e "$pid \t$cpu \t${numa_map[$cpu]}"
done

#for pid in $PIDS; do
#  taskset -c -p $pid
#done 
