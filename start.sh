# v_baidu: 720_bronze_IPPP_hard_normal_hevc 720_silver_IPPP_hard_normal_h264 720_gold_IPPP_hard_normal_h264 720_gold_2pass_hard_normal_h264 1k_gold_IPPP_hard_normal_h264 1k_gold_2pass_hard_normal_h264 4k_gold_IPPP_hard_normal_h264
# ai_bench: mobilenet_v1 mobilenet_v2 resnet retinaface yolov3 yolov5 yolov7
# ai_video: deblur_mem_1 deart_mem_1
nohup python3.8 perf.py --host=192.168.20.103 --mode=v_baidu --opts=720_bronze_IPPP_hard_normal_hevc > perf.log 2>&1 &
