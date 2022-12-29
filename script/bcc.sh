
/usr/share/bcc/tools/stackcount t:syscalls:sys_enter_sched_yield -D 10 -p `pgrep test|head -1`
