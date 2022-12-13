#docker run --rm -itd --name bm0 --net=host --runtime=vastai -e VASTAI_VISIBLE_DEVICES=0 -v /etc/localtime:/etc/localtime -v /opt/data:/opt/data reg.devops.com/base/benchmark:v1.2.2

#docker exec bm0 bash -c "source /etc/profile; cd /opt/benchmark; python3 main.py -m /opt/data/v1.2.2/mobilenet_v1"
#docker exec bm0 bash -c "source /etc/profile; cd /opt/benchmark; python3 main.py -m /opt/data/v1.2.2/mobilenet_v2"

ITER=1000000
PERF=/opt/benchmark/conf/mobilenet/perf
MODEL=mobilenet_v1-keras-keras-fp16-none-224_224-runstream-1.json
#MODEL=mobilenet_v2-timm-onnx-int8-percentile-224_224-runstream-1.json

docker exec bm0 bash -c "source /etc/profile; /opt/vaststream/tool/vaTest -d 0 -b 100 -v 1 -p -1 -i $ITER -j $PERF/$MODEL --batch 1"

