############################################
# apt install python3.8 python3.8-dev
# python3.8 -m pip install cython numpy pandas
# python3 -m pip install pandas plotly -i https://pypi.tuna.tsinghua.edu.cn/simple
# yum install cmake
# git clone --recursive https://github.com/intel/pcm
# mkdir pcm/build; cd pcm/build; cmake ..; make; make install
############################################
import time, subprocess, pandas as pd
import plotly.graph_objects as go

def plot_mem(folder,card):
    data = pd.read_csv(folder+'/'+card+'/mem.csv', header=[0,1])
    data.columns = data.columns.map(''.join)
    pd.set_option('display.max_columns', 500)
    pd.set_option('display.max_rows', 500)
    pd.set_option('display.expand_frame_repr', False)
    data.insert(0, 'index', range(1, 1 + len(data)))
    line1 = go.Scatter(x=data['index'], y=data['SKT0Mem Read (MB/s)'], name='mem_read0')
    line2 = go.Scatter(x=data['index'], y=data['SKT0Mem Write (MB/s)'], name='mem_write0')
    line3 = go.Scatter(x=data['index'], y=data['SKT1Mem Read (MB/s)'], name='mem_read1')
    line4 = go.Scatter(x=data['index'], y=data['SKT1Mem Write (MB/s)'], name='mem_write1')
    fig = go.Figure([line1,line2,line3,line4])
    fig.update_layout(
        title=card+" memory",
        # xaxis_title="Index",
        # yaxis_title="Performance Trends"
        # font_family="Courier New",
        # font_color="blue",
        # title_font_family="Times New Roman",
        # title_font_color="red",
        title_font_size=20,
        #legend_title_font_color="green"
    )
    #fig.show()
    fig.write_html(folder+'/'+card+"/mem.html")
def plot_mem_pmt(folder,card):
    data = pd.read_csv(folder+'/'+card+'/mem.csv')
    #data.columns = data.columns.map(''.join)
    pd.set_option('display.max_columns', 500)
    pd.set_option('display.max_rows', 500)
    pd.set_option('display.expand_frame_repr', False)
    data.insert(0, 'index', range(1, 1 + len(data)))
    data.drop(index=0,inplace=True)
    #data = data.iloc[1:, :]
    #S0Read,S0Write,S1Read,S1Write       (MB/s)

    line1 = go.Scatter(x=data['index'], y=data['S0Read'], name='mem_read0')
    line2 = go.Scatter(x=data['index'], y=data['S0Write'], name='mem_write0')
    line3 = go.Scatter(x=data['index'], y=data['S1Read'], name='mem_read1')
    line4 = go.Scatter(x=data['index'], y=data['S1Write'], name='mem_write1')
    fig = go.Figure([line1,line2,line3,line4])
    fig.update_layout(
        title=card+" memory",
        # xaxis_title="Index",
        # yaxis_title="Performance Trends"
        # font_family="Courier New",
        # font_color="blue",
        # title_font_family="Times New Roman",
        # title_font_color="red",
        title_font_size=20,
        #legend_title_font_color="green"
    )
    #fig.show()
    fig.write_html(folder+'/'+card+"/mem.html")
def plot_pcie(folder,card):
    data1 = pd.read_csv(folder+'/'+card+'/pcie.csv')
    #print(data1)
    data_p0 = data1[(data1["Skt"] == '0')].copy()
    data_p0.insert(0, 'index', range(1, 1 + len(data_p0)))
    data_p1 = data1[(data1["Skt"] == '1')].copy()
    data_p1.insert(0, 'index', range(1, 1 + len(data_p1)))
    #data_p0[["PCIe Rd (B)", "PCIe Wr (B)"]] = data_p0[["PCIe Rd (B)", "PCIe Wr (B)"]].apply(pd.to_numeric)
    #data_p1[["PCIe Rd (B)", "PCIe Wr (B)"]] = data_p1[["PCIe Rd (B)", "PCIe Wr (B)"]].apply(pd.to_numeric)
    data_p0["PCIe Rd (B)"] = pd.to_numeric(data_p0["PCIe Rd (B)"], errors='coerce')
    data_p0["PCIe Wr (B)"] = pd.to_numeric(data_p0["PCIe Wr (B)"], errors='coerce')
    data_p1["PCIe Rd (B)"] = pd.to_numeric(data_p1["PCIe Rd (B)"], errors='coerce')
    data_p1["PCIe Wr (B)"] = pd.to_numeric(data_p1["PCIe Wr (B)"], errors='coerce')

    line1 = go.Scatter(x=data_p0['index'], y=data_p0['PCIe Rd (B)'], name='pcie_read0')
    line2 = go.Scatter(x=data_p0['index'], y=data_p0['PCIe Wr (B)'], name='pcie_write0')
    line3 = go.Scatter(x=data_p1['index'], y=data_p1['PCIe Rd (B)'], name='pcie_read1')
    line4 = go.Scatter(x=data_p1['index'], y=data_p1['PCIe Wr (B)'], name='pcie_write1')
    fig = go.Figure([line1,line2,line3,line4])
    fig.update_layout(
        title=card + " pcie",
        # xaxis_title="Index",
        # yaxis_title="Performance Trends"
        # font_family="Courier New",
        # font_color="blue",
        # title_font_family="Times New Roman",
        # title_font_color="red",
        title_font_size=20,
        #legend_title_font_color="green"
    )
    #fig.show()
    fig.write_html(folder+'/'+card+"/pcie.html")

def plot_pcie_pmt(folder,card):
    file=folder+'/'+card+'/pcie.csv'
    output=exec_cmd("head -20 {} |awk -F, '{{print $2}}'|grep -v Bus|sort|uniq".format(file))
    pcie_array=output.split('\n')
    data1 = pd.read_csv(file)
    all_lines=[]
    for pci in pcie_array:
        data = data1[(data1["Bus"] == pci)].copy()
        data.insert(0, 'index', range(1, 1 + len(data)))
        #print(data)
        data["IB read"] = pd.to_numeric(data["IB read"], errors='coerce')
        data["IB write"] = pd.to_numeric(data["IB write"], errors='coerce')
        data["OB read"] = pd.to_numeric(data["OB read"], errors='coerce')
        data["OB write"] = pd.to_numeric(data["OB write"], errors='coerce')
        line1 = go.Scatter(x=data['index'], y=data['IB read'], name=pci+' InRead')
        line2 = go.Scatter(x=data['index'], y=data['IB write'], name=pci+' InWrite')
        line3 = go.Scatter(x=data['index'], y=data['OB read'], name=pci+' OutRead')
        line4 = go.Scatter(x=data['index'], y=data['OB write'], name=pci+' OutWrite')
        all_lines.append(line1)
        all_lines.append(line2)
        all_lines.append(line3)
        all_lines.append(line4)
    fig = go.Figure(all_lines)
    fig.update_layout(
        title = str(len(pcie_array)) + " cards bandwidth",
        # xaxis_title="Index",
        # yaxis_title="Performance Trends"
        # font_family="Courier New",
        # font_color="blue",
        # title_font_family="Times New Roman",
        # title_font_color="red",
        title_font_size=20,
        # legend_title_font_color="green"
    )
    #fig.show()
    fig.write_html(folder + '/' + card + "/pcie.html")

def plot_cpu(folder,card,index):
    data2 = pd.read_csv(folder+'/'+card+'/cpu.csv', header=[1], delim_whitespace=True)
    #print(data2)
    data_cpu = data2[(data2["CPU"] == index)].copy()
    #print(data_cpu.head())
    data_cpu.insert(0, 'index', range(1, 1 + len(data_cpu)))
    data_cpu[["%idle"]] = data_cpu[["%idle"]].apply(pd.to_numeric)
    line1 = go.Scatter(x=data_cpu['index'], y=100-data_cpu['%idle'], name='cpu_idle')
    fig = go.Figure([line1])
    fig.update_layout(
            title=card + " cpu_"+index+"%",
            # xaxis_title="Index",
            # yaxis_title="Performance Trends"
            # font_family="Courier New",
            # font_color="blue",
            # title_font_family="Times New Roman",
            # title_font_color="red",
            title_font_size=20,
            #legend_title_font_color="green"
        )
    fig.write_html(folder+'/'+card+"/cpu"+index+".html")
def plot_metrics(path,card):
    #plot_pcie(path,card)
    #plot_mem(path,card)
    plot_pcie_pmt(path,card)
    plot_mem_pmt(path,card)
    plot_cpu(path,card,'all')
    plot_cpu(path,card,'0')
    #exec_cmd("mv perf.log results/{}/".format(card))
    exec_cmd("rm -rf results/{}.tgz".format(card))
    exec_cmd("tar zcf results/{}.tgz results/{}".format(card,card))

def plot_va1v():
    path='/Users/xuan/Desktop/V1A1/logs_vaprofiler/'
    path='/Users/xuan/Desktop/V1A1/logs/'
    plot_metrics(path, 'card0')
    plot_metrics(path, 'card1')
    plot_metrics(path, 'card2')
def plot_ve1s():
    path='/Users/xuan/Desktop/VE1S/'
    plot_metrics(path, '2VE1S')

def exec_cmd(cmd):
    p=subprocess.run([cmd], shell=True, check=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out=p.stdout.decode('utf-8').strip()
    return out
def write_perf_file(folder, script_file, metrics=['mpstat','mem','pcie']):
    exec_cmd("mkdir -p {}".format(folder))
    content = "#!/bin/bash"
    if 'mpstat' in metrics:
        content+="""
mpstat -P ALL 2     > {DIR}/cpu.csv 2>&1 &""".format(DIR=folder)
        #print(content)
    if 'mem' in metrics:
        content+="""
pcm-memory 2 -nc -csv={DIR}/mem.csv  > /dev/null 2>&1 &""".format(DIR=folder)
        #print(content)
    if 'pcie' in metrics:
        content+="""
pcm-pcie     -B  -csv={DIR}/pcie.csv > /dev/null 2>&1 &""".format(DIR=folder)
        #print(content)
    with open(folder+'/'+script_file, 'w') as f:
        f.write(content)
def start_perf(host,work_dir,case_name,local_dir):
    #result_folder= "/home/test"
    perf_file="start_perf.sh"
    #work_folder=work_dir+'/'+sub_folder
    send_file_remote('root', host, local_dir+perf_file, work_dir)
    #write_perf_file(work_folder, perf_file, ['mpstat','mem','pcie'])
    run_script_remote('root', host, work_dir, perf_file, case_name, False)
def stop_perf(host):
    exec_cmd("ssh root@{} killall mpstat pcie pmt sar".format(host))

workloads={
    #'v_baidu':     ['loop_docker.sh', 'docker_video.sh','load_video2.sh'],
    'v_baidu':     ['loop_docker_numa1.sh', 'docker_video.sh','load_video2.sh'],
    'v_transcode': ['docker_video.sh','load_video.sh'],
    'a_resnet50':  ['docker_resnet50.sh'],
    'a_bert':      ['docker_bert.sh','load_bert.sh'],
    #'a_yolo':     ['docker_yolo.sh'],
}
def send_file_remote(user, ip, file, target_path):
    cmd = "scp {} {}@{}:{}".format(file, user, ip, target_path)
    # cmd="scp /Users/xuan/Desktop/VE1S/docker_ai.sh root@192.168.20.48:/home/test/test1"
    print(cmd)
    out=exec_cmd(cmd)
    print(out)
def download_results(user, ip, file, target_path):
    cmd = "scp -r {}@{}:{} {} ".format(user, ip, file, target_path)
    # cmd="scp -r root@192.168.20.209:/home/test/dataset/logs/va1v_video1 /Users/xuan/Desktop/VA1V/"
    print(cmd)
    out=exec_cmd(cmd)
    print(out)
def run_script_remote(user, ip, path, file, opt, wait=True):
    if wait:
        cmd="ssh {}@{} 'cd {}; ./{} {}'".format(user, ip, path, file, opt)
    else:
        cmd = "ssh {}@{} 'cd {}; ./{} {}' &".format(user, ip, path, file, opt)
    print(cmd)
    out=exec_cmd(cmd)
    print(out)
    #time.sleep(10)
def write_docker_file(folder, script_file, workload="video"):
    exec_cmd("mkdir -p {}".format(folder))
    content = """#!/bin/bash
IDX=${1:-0}
#File="ParkScene_1920x1080_30fps_8M.mp4"
#URL="http://qa.vastai.com/datasets/$File"
ImageID=2c783a6d863a
host_dataset_path=/home/test/dataset
NIDX=$((IDX+1))
PCI_N=`lspci|grep accelerators | sed -n ${NIDX}p|awk '{print $1}'`
NODE=`cat /sys/bus/pci/devices/0000:$PCI_N/numa_node`
cgcreate -g cpuset:numanode$NODE
CPUS1=`lscpu|grep node$NODE|awk '{print $4}'`
echo "$CPUS1" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.cpus
echo "$NODE" > /sys/fs/cgroup/cpuset/numanode$NODE/cpuset.mems
DIR=/opt/vastai/vaststream/samples/dataset/
SH="$DIR/load_video.sh"
docker run --rm -itd --name card$IDX --cgroup-parent=numanode$NODE \
  --runtime=vastai -e VASTAI_VISIBLE_DEVICES=$IDX \
  -v ${host_dataset_path}:/opt/vastai/vaststream/samples/dataset \
  ${ImageID} /bin/bash

DIR=/opt/vastai/vaststream/samples/dataset/
docker exec card$IDX bash -c "source /etc/profile && sh $DIR/load_video.sh 1"
""".format(DIR=folder)
    #print(content)

    with open(folder+'/'+script_file, 'w') as f:
        f.write(content)
def start_dockers(host,mode,path,local_dir,case):
    # scp docker_ai.sh to host:path
    for script in workloads[mode]:
        send_file_remote('root', host, local_dir+script, path)
    #send_file_remote('root', host, folder+"vastai_pci.ko", path)  # already installed
    run_script_remote('root', host, path, workloads[mode][0], case)
def test_and_monitor(host,name,case):
    path1="/home/test/dataset/"  #remote
    folder = 'script/'  # local
    full="{}_{}".format(name,case)
    start_perf(host,path1,full,folder)
    start_dockers(host,name,path1,folder,case)
    time.sleep(5)
    #wait_for_pid_finish(workloads[name])
    stop_perf(host)
    download_results('root', host, path1+'/logs/'+full, "results")
    print("plot charts")
    plot_metrics("results",full)

def baidu_cases():
  test_and_monitor("192.168.20.209","v_baidu","720_bronze_IPPP_hard_normal_hevc")
  #time.sleep(60)
  #test_and_monitor("192.168.20.209","v_baidu","720_silver_IPPP_hard_normal_h264")
  #time.sleep(60)
  #test_and_monitor("192.168.20.209","v_baidu","720_gold_IPPP_hard_normal_h264")
  #time.sleep(60)
  #test_and_monitor("192.168.20.209","v_baidu","1k_gold_2pass_hard_normal_h264")
  #time.sleep(60)
  #test_and_monitor("192.168.20.209","v_baidu","1k_gold_IPPP_hard_normal_h264")

  #test_and_monitor("192.168.20.209","v_baidu","4k_gold_IPPP_hard_normal_h264")
  #test_and_monitor("192.168.20.209","v_baidu", "720_gold_2pass_hard_normal_h264")
  #test_and_monitor("192.168.20.209","v_transcode")
  #test_and_monitor("192.168.20.209","a_resnet50")
  #test_and_monitor("192.168.20.209","a_bert")
  #plot_metrics('/Users/xuan/Desktop/va1v_BD/script/',"va1v_case1")

baidu_cases()
