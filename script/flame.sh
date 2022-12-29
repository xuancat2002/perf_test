#perf record -F99 -e cpu-clock -ag -- sleep 30
#perf record -F99 -o perf.data -ag -- sleep 30
perf record -F99 -o perf.data -g -p `pgrep test|head -1` -- sleep 30
perf script -i perf.data > perf.unfold
git clone https://github.com/brendangregg/FlameGraph.git
FlameGraph/stackcollapse-perf.pl perf.unfold > perf.folded
FlameGraph/flamegraph.pl perf.folded > perf.svg
