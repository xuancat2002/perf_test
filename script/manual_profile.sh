while true; do
    processor_num=`ps -ef | grep test | wc -l`
    if [ $processor_num -gt 1 ];then
        echo "found test processor_num=$processor_num"
        ps -ef|grep test
        break
    else
        echo "wait test"
        sleep 5
    fi
done


IDX=0
EXEC=/opt/vastai/vaststream/release/samples/tmp/
#docker exec ai_card$IDX bash -c "cd $EXEC; ./flame.sh"
#docker exec ai_card$IDX bash -c "perf top "
#/usr/share/bcc/tools/syscount -p `pgrep test|head -1` -d 10
/usr/share/bcc/tools/stackcount t:syscalls:sys_enter_sched_yield -D 10 -p `pgrep test|head -1`
#docker exec -it ai_card0 bash -c "/usr/share/bcc/tools/stackcount t:syscalls:sys_enter_sched_yield -D 10 -p `pgrep test|head -1`"
