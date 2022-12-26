#!/bin/bash
count=${1:-1}
mode=${2:-deart}  # deart/deblur/all

if [ "$mode" = "all" ]; then
  json_file=`ls json_file/*.json`
else
  json_file=`ls json_file/$mode*.json`
fi

##clean
rm -rf edsr_result deart_*_vacc pytorch_deart_int8_percentile* deart_results_sum.txt deblur_results_sum.txt deblur_results deart_results current_test_round*  *Y sit_488x488_vacc outfile performance start.txt gen_gold_result.txt test_result_all.txt timelog.txt test_result_fail.txt round_time.txt
echo ========================================
echo "The previous results has been deleted"
echo ========================================

## environment
#yum install -y bc
make clean
make
source /etc/profile
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../../vacl/lib/

date >  start.txt
nodes=`ls /dev | grep vacc`
node=`echo ${nodes} | cut -d " " -f 1`
node1=`echo ${node##*vacc}`
node=`echo ${nodes} | cut -d " " -f 2`
node2=`echo ${node##*vacc}`

mkdir deblur_results
mkdir deart_results

function check_performance()
{
   sum0=$(grep -rni "ai_util" $1 | awk '{if($3 !="0.00%" )print $3}'  |awk 'NR>2{print $0}' | awk 'NR>1{print line}{line=$0}' | awk 'NR>1{print line}{line=$0}' | awk 'NR%2==1{sum+=$0} END {print sum}')
   line0=$(grep -rni "ai_util" $1 | awk '{if($3 !="0.00%" )print $3}' |awk 'NR>2{print $0}' | awk 'NR>1{print line}{line=$0}' | awk 'NR>1{print line}{line=$0}' | awk 'NR%2==1' | wc -l)
   sum1=$(grep -rni "ai_util" $1 | awk '{if($3 !="0.00%" )print $3}'  |awk 'NR>2{print $0}' | awk 'NR>1{print line}{line=$0}' | awk 'NR>1{print line}{line=$0}' | awk 'NR%2==0{sum+=$0} END {print sum}')
   line1=$(grep -rni "ai_util" $1 | awk '{if($3 !="0.00%" )print $3}' |awk 'NR>2{print $0}' | awk 'NR>1{print line}{line=$0}' | awk 'NR>1{print line}{line=$0}' | awk 'NR%2==0' | wc -l)
   avg0=$(echo "$sum0 $line0" | awk '{printf("%.5f", $1/$2)}')
   avg1=$(echo "$sum1 $line1" | awk '{printf("%.5f", $1/$2)}')
   echo "die0: sum =" $sum0 " line = " $line0 " avg = " $avg0
   echo "die1: sum =" $sum1 " line = " $line1 " avg = " $avg1
   if [ `echo "$avg0 > 90.0"|bc` -eq 1 ] && [ `echo "$avg1 > 90.0"|bc` -eq 1 ];then
      echo "*******************************************" >>test_result_all.txt
      echo  the network is $3, this round $2 are pass ,all of the ai_util are full,the die0 is $"$avg0", the die1 is "$avg1"   >> test_result_all.txt
      echo "*******************************************" >> test_result_all.txt
   else
      echo "*******************************************" >>test_result_all.txt
      echo  the network is $3, this round $2 are failed ,the die0 is $"$avg0", the die1 is "$avg1"   >> test_result_all.txt
      echo "*******************************************" >> test_result_all.txt
   fi
}

<<ACC
for file in ${json_file[@]}
do 
	./test -d $node1 -b 21  --batch 1 -j $file -v 0  
	wait
        json_name=`echo $(basename $file .json)`
	height=`echo $json_name | cut -d '_' -f 2`
	width=`echo $json_name | cut -d '_' -f 3`
	if [ "`echo $file |  grep deblur`" != '' ]; then 
		python3 deblur_metrics/from_pytorch_deblur_int8_eval_runstream.py --src_path  edsr_result  --dst_path ../datasets/deblur_datasets/data_${height}_${width}/ >  deblur_results/deblur_${height}_${width}_results.txt
                echo ===================  ${file}  =======================   >> deblur_results_sum.txt
                tail -n 1 deblur_results/deblur_${height}_${width}_results.txt >> deblur_results_sum.txt                
	elif [ "`echo $file |  grep deart`" != '' ]; then
		mv deart_*_vacc pytorch_deart_int8_percentile_${height}_${width}_stream
		python3 deart_metrics/eval_1080p_vacc_stream.py --height $height --width $width >  deart_results/deart_${height}_${width}_results.txt 
		echo ===================  ${file}  =======================   >> deart_results_sum.txt
		tail -n 1 deart_results/deart_${height}_${width}_results.txt >> deart_results_sum.txt
	fi
        rm -rf edsr_result deart_*_vacc
done
ACC
#<<EOF
for j in $(seq 1 $count)
do
starttime=`date +%s%3N`
#  echo "round$j starttime: `date +"%Y-%m-%d %H:%M:%S"`" >> time.txt
  mkdir current_test_round$j
  for file in ${json_file[@]}
   do
      json_name=`echo $(basename $file .json)`
       start=`date +%s%3N`

           #mkdir -p performance/$j
           #./run_de_perf.sh $file 1 ./performance/$j/$json_name"_performance.txt" | tee current_test_round$j/$json_name".txt"
           ./run_de_perf.sh $file 1
           #check_performance ./performance/$j/$json_name"_performance.txt" $j $file

       end=`date +%s%3N`
       totaltime=`expr $end - $start`
      echo Execution ${json_name}_${j} need time was $totaltime million seconds >> timelog.txt
      console_log="/opt/vastai/vaststream/release/samples/common/current_test_round${j}/${json_name}.txt"
      if [ ! -f "$console_log" ];then
                echo "*******************************************" >>test_result_all.txt
                echo  the console log of ${json_name}_$j does not exist, please check  >> test_result_all.txt
                echo "*******************************************" >>test_result_all.txt
      else
        results=`cat current_test_round${j}/${json_name}".txt" | grep "Mismatch" | grep -v "Mismatch: 0"`
        echo $results
        if [ "$results" != "" ]; then
          mkdir -p fail/${j}
          cp -rf current_test_round${j}/$json_name".txt" fail/${j} -avf
          echo this round $j $json_name have mismatch, please check >> test_result_fail.txt
        fi
      fi
   sleep 55
   done
   run_result=`cat test_result_all.txt | grep "console"`
   if [ "$run_result" != "" ]; then
      echo "*******************************************" >>test_result_all.txt
      echo There are networks that have not been running in round $j, please check  >> test_result_all.txt
      echo "*******************************************" >> test_result_all.txt
   fi
   results=`cat current_test_round${j}/*.txt | grep "Mismatch" | grep -v "Mismatch: 0"`
   echo $results
   if [ "$results" == "" ]; then
      echo "*******************************************" >>test_result_all.txt
      echo network test is finished, this round $j are match, the result is pass                    >> test_result_all.txt
      echo "*******************************************" >> test_result_all.txt
   else
      echo "*******************************************" >> test_result_all.txt
      echo network test is finished, this round $j have mismatch, please check test_result_fail.txt  >> test_result_all.txt
      echo "*******************************************"  >> test_result_all.txt
   fi
endtime=`date +%s%3N`
# count duration
roundtime=`expr $endtime - $starttime`
   echo "****************************************************">>round_time.txt
   echo round$j need $roundtime million seconds >> round_time.txt
   echo "****************************************************">>round_time.txt
   rm -rf current_test_round$j
done

#EOF
date >> start.txt
