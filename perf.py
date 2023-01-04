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

def plot_fps(folder,card):
    raw_file="{}/utilize.log".format(folder+'/'+card)
    cmd="head -1000 {}|grep Time|sort |uniq|wc -l".format(raw_file)
    n = int(exec_cmd(cmd))
    #print("plot_fps: {}".format(n))
    fps_file="{}/fps.log".format(folder+'/'+card)
    cmd="echo \"die  fps\" > {}".format(fps_file)
    exec_cmd(cmd)
    cmd="grep \"^vdsp->ai@ai\" {}|awk '{{if (i%{}==0) {{i=0}}; printf \"die%d  %d\\n\",i,$4; i++}}' >> {}".format(raw_file,n,fps_file)
    out=exec_cmd(cmd)
    #print(out)
    pd.set_option('display.max_columns', 500)
    pd.set_option('display.max_rows', 500)
    pd.set_option('display.expand_frame_repr', False)
    data = pd.read_csv(fps_file, delim_whitespace=True)
    data=data.iloc[::2]
    data[["fps"]] = data[["fps"]].apply(pd.to_numeric)
    all_lines = []
    for die in range(n):
        name="die{}".format(die)
        #print(name)
        data1 = data[(data["die"] == name)].copy()
        data1.insert(0, 'index', range(1, 1+len(data1)))
        fps=go.Scatter(x=data1['index'], y=data1['fps'], name=name+'.fps')
        all_lines.append(fps)

    fig = go.Figure(all_lines)
    fig.update_layout(
            title=card + " fps",
            title_font_size=20,
            # xaxis_title="Index",
            # yaxis_title="Performance Trends"
            # font_family="Courier New",
            # font_color="blue",
            # title_font_family="Times New Roman",
            # title_font_color="red",
            #legend_title_font_color="green"
        )
    fig.write_html(folder+'/'+card+"/fps.html")
def plot_disk(folder,card):
    file=folder+'/'+card+'/disk.csv'
    output = exec_cmd("head -20 {}|grep -v DEV|grep -v Linux |awk '{{print $3}}'|sort|uniq".format(file))
    disk_array=output.split('\n')
    disk_array = [x for x in disk_array if not x.startswith('dev253')]
    data = pd.read_csv(file, header=[1], delim_whitespace=True)
    pd.set_option('display.max_columns', 500)
    pd.set_option('display.max_rows', 500)
    pd.set_option('display.expand_frame_repr', False)
    data.drop(data[data['%util'] == '%util'].index, inplace=True)
    data[["%util"]] = data[["%util"]].apply(pd.to_numeric)
    data[["rkB/s"]] = data[["rkB/s"]].apply(pd.to_numeric)
    data[["wkB/s"]] = data[["wkB/s"]].apply(pd.to_numeric)
    # data["%util"] = pd.to_numeric(data["%util"], errors='coerce')
    all_lines = []
    for disk in disk_array:
        # tps     rkB/s     wkB/s   areq-sz    aqu-sz     await     svctm     %util
        data1 = data[(data["DEV"] == disk)].copy()
        data1.insert(0, 'index', range(1, 1+len(data1)))
        util=go.Scatter(x=data1['index'], y=data1['%util'], name=disk+'%util')
        tps =go.Scatter(x=data1['index'], y=data1['tps'],   name=disk+'.tps')
        rd = go.Scatter(x=data1['index'], y=data1['rkB/s']/1000, name=disk+'.readMB')
        wt = go.Scatter(x=data1['index'], y=data1['wkB/s']/1000, name=disk+'.writeMB')
        all_lines.append(util)
        all_lines.append(tps)
        all_lines.append(rd)
        all_lines.append(wt)

    fig = go.Figure(all_lines)
    fig.update_layout(
            title=card + " disk%",
            title_font_size=20,
            # xaxis_title="Index",
            # yaxis_title="Performance Trends"
            # font_family="Courier New",
            # font_color="blue",
            # title_font_family="Times New Roman",
            # title_font_color="red",
            #legend_title_font_color="green"
        )
    fig.write_html(folder+'/'+card+"/disk.html")
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
        title = str(len(pcie_array)) + " cards pcie bandwidth",
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
    total = go.Scatter(x=data_cpu['index'], y=100-data_cpu['%idle'], name='total')
    sys = go.Scatter(x=data_cpu['index'], y=data_cpu['%sys'], name='sys')
    iowait = go.Scatter(x=data_cpu['index'], y=data_cpu['%iowait'], name='iowait')
    irq = go.Scatter(x=data_cpu['index'], y=data_cpu['%irq'], name='irq')
    fig = go.Figure([total,sys,iowait,irq])
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
def plot_vastai_dmon(folder,card):
    file=folder+'/'+card+'/dmon.log'
    output = exec_cmd("head -100 {}|grep -v Vastai|grep -v '<1/1>'|grep -v '\---' |grep -v 'aic' |awk '{{print $1}}'|sort|uniq".format(file))
    vastai_array=output.split('\n')
    #print(vastai_array)
    pwr_all_lines = []
    temp_all_lines = []
    mem_all_lines = []
    oclk_all_lines = []
    dclk_all_lines = []
    eclk_all_lines = []
    ai_all_lines = []
    dec_all_lines = []
    enc_all_lines = []
    for chip in vastai_array:
        exec_cmd("echo 'aic/die   pwr(W)   temp(C)   %mem   oclk(MHz)   dclk(MHz)   eclk(MHz)     %ai    %dec    %enc' > tmp.csv")
        exec_cmd("grep {} {} |grep -v '<' >> tmp.csv".format(chip, file))
        data1 = pd.read_csv("tmp.csv",delim_whitespace=True)
        data1=data1.iloc[::2]
        data1.insert(0, 'index', range(1, 1 + len(data1)))
        data1["pwr(W)"] = pd.to_numeric(data1["pwr(W)"], errors='coerce')
        data1["temp(C)"] = pd.to_numeric(data1["temp(C)"], errors='coerce')
        data1["%mem"] = pd.to_numeric(data1["%mem"], errors='coerce')
        data1["oclk(MHz)"] = pd.to_numeric(data1["oclk(MHz)"], errors='coerce')
        data1["dclk(MHz)"] = pd.to_numeric(data1["dclk(MHz)"], errors='coerce')
        data1["eclk(MHz)"] = pd.to_numeric(data1["eclk(MHz)"], errors='coerce')
        data1["%ai"] = pd.to_numeric(data1["%ai"], errors='coerce')
        data1["%dec"] = pd.to_numeric(data1["%dec"], errors='coerce')
        data1["%enc"] = pd.to_numeric(data1["%enc"], errors='coerce')
        line_pwr = go.Scatter(x=data1['index'], y=data1['pwr(W)'], name=chip + ' pwr(W)')
        line_temp = go.Scatter(x=data1['index'], y=data1['temp(C)'], name=chip + ' temp(C)')
        line_mem = go.Scatter(x=data1['index'], y=data1['%mem'], name=chip + ' %mem')
        line_oclk = go.Scatter(x=data1['index'], y=data1['oclk(MHz)'], name=chip + ' oclk(MHz)')
        line_dclk = go.Scatter(x=data1['index'], y=data1['dclk(MHz)'], name=chip + ' dclk(MHz)')
        line_eclk = go.Scatter(x=data1['index'], y=data1['eclk(MHz)'], name=chip + ' eclk(MHz)')
        line_ai = go.Scatter(x=data1['index'], y=data1['%ai'], name=chip + ' %ai')
        line_dec = go.Scatter(x=data1['index'], y=data1['%dec'], name=chip + ' %dec')
        line_enc = go.Scatter(x=data1['index'], y=data1['%enc'], name=chip + ' %enc')
        pwr_all_lines.append(line_pwr)
        temp_all_lines.append(line_temp)
        mem_all_lines.append(line_mem)
        oclk_all_lines.append(line_oclk)
        dclk_all_lines.append(line_dclk)
        eclk_all_lines.append(line_eclk)
        ai_all_lines.append(line_ai)
        dec_all_lines.append(line_dec)
        enc_all_lines.append(line_enc)
    fig_pwr = go.Figure(pwr_all_lines)
    fig_temp = go.Figure(temp_all_lines)
    fig_mem = go.Figure(mem_all_lines)
    fig_oclk = go.Figure(oclk_all_lines)
    fig_dclk = go.Figure(dclk_all_lines)
    fig_eclk = go.Figure(eclk_all_lines)
    fig_ai = go.Figure(ai_all_lines)
    fig_dec = go.Figure(dec_all_lines)
    fig_enc = go.Figure(enc_all_lines)
    fig_pwr.update_layout(
        title=str(len(vastai_array)) + " vastai pwr(W)",
        # xaxis_title="Index",
        # yaxis_title="Performance Trends"
        # font_family="Courier New",
        # font_color="blue",
        # title_font_family="Times New Roman",
        # title_font_color="red",
        title_font_size=20,
        # legend_title_font_color="green"
    )
    fig_temp.update_layout(
        title=str(len(vastai_array)) + " vastai temp(C)",
        title_font_size=20,
    )
    fig_mem.update_layout(
        title=str(len(vastai_array)) + " vastai memory",
        title_font_size=20,
    )
    fig_oclk.update_layout(
        title=str(len(vastai_array)) + " vastai oclk(MHz)",
        title_font_size=20,
    )
    fig_dclk.update_layout(
        title=str(len(vastai_array)) + " vastai dclk(MHz)",
        title_font_size=20,
    )
    fig_eclk.update_layout(
        title=str(len(vastai_array)) + " vastai eclk(MHz)",
        title_font_size=20,
    )
    fig_ai.update_layout(
        title=str(len(vastai_array)) + " vastai %AI",
        title_font_size=20,
    )
    fig_dec.update_layout(
        title=str(len(vastai_array)) + " vastai %decode",
        title_font_size=20,
    )
    fig_enc.update_layout(
        title=str(len(vastai_array)) + " vastai %encode",
        title_font_size=20,
    )
    #fig_pwr.show()
    #fig_temp.show()
    #fig_mem.show()
    #fig_oclk.show()
    #fig_dclk.show()
    #fig_eclk.show()
    #fig_ai.show()
    #fig_dec.show()
    #fig_enc.show()
    #fig.write_html(folder + '/' + card + "/dmon.html")
    fig_pwr.write_html(folder + '/' + card + "/dmon_pwr.html")
    fig_temp.write_html(folder + '/' + card + "/dmon_temp.html")
    fig_mem.write_html(folder + '/' + card + "/dmon_mem.html")
    fig_oclk.write_html(folder + '/' + card + "/dmon_oclk.html")
    fig_dclk.write_html(folder + '/' + card + "/dmon_dclk.html")
    fig_eclk.write_html(folder + '/' + card + "/dmon_eclk.html")
    fig_ai.write_html(folder + '/' + card + "/dmon_ai.html")
    fig_dec.write_html(folder + '/' + card + "/dmon_dec.html")
    fig_enc.write_html(folder + '/' + card + "/dmon_enc.html")

def plot_metrics(path,card):
    #plot_pcie(path,card)
    #plot_mem(path,card)
    plot_fps(path,card)
    plot_disk(path,card)
    plot_vastai_dmon(path,card)
    plot_pcie_pmt(path,card)
    plot_mem_pmt(path,card)
    plot_cpu(path,card,'all')
    #plot_cpu(path,card,'0')
    #exec_cmd("mv perf.log results/{}/".format(card))
    exec_cmd("rm -rf results/{}.tgz".format(card))
    time.sleep(2)
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
    exec_cmd("ssh root@{} killall vasmi mpstat pcie mem sar".format(host))

workloads={
    #'v_baidu':    ['loop_docker_numa1.sh', 'docker_video.sh','load_video2.sh'],
    'v_baidu':     ['loop_docker.sh',       'docker_video.sh','load_video2.sh'],
    'v_transcode': ['docker_video.sh','load_video.sh'],
    'a_resnet50':  ['loop_docker_resnet50.sh', 'docker_resnet50.sh'],
    'a_bert':      ['loop_docker_bert.sh',     'docker_bert.sh','load_bert.sh'],
    'ai_bench':    ['loop_docker_ai_cnn.sh',   'docker_ai_cnn.sh'],
    'ai_video':    ['loop_docker_ai_video.sh', 'docker_ai_video.sh', 'run_de.sh', 'run_de_perf.sh'],
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
        cmd="ssh {}@{} 'cd {}; ./{} {}' &".format(user, ip, path, file, opt)
    print(cmd, flush=True)
    out=exec_cmd(cmd)
    print(out, flush=True)
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
    run_script_remote('root', host, path, workloads[mode][0], mode+'.'+case)
def test_and_monitor(host,name,case):
    path1="/home/test/dataset/"  #remote
    folder = 'script/'  # local
    full="{}.{}".format(name,case)
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

def modeling_cases():
  #test_and_monitor("192.168.20.209","a_resnet50","5")
  #test_and_monitor("192.168.20.209","a_bert","5")

  #test_and_monitor("192.168.20.209","ai_bench","mobilenet_v1")
  #test_and_monitor("192.168.20.209","ai_bench","mobilenet_v2")
  #test_and_monitor("192.168.20.209","ai_bench","resnet")
  #test_and_monitor("192.168.20.209","ai_bench","retinaface")
  #test_and_monitor("192.168.20.209","ai_bench","yolov3")
  #test_and_monitor("192.168.20.209","ai_bench","yolov5")
  #test_and_monitor("192.168.20.209","ai_bench","yolov7")

  test_and_monitor("192.168.20.209","ai_video","deblur_mem_1")
  test_and_monitor("192.168.20.209","ai_video","deart_mem_1")
  #test_and_monitor("192.168.20.209","ai_video","deblur_disk_1")
  #test_and_monitor("192.168.20.209","ai_video","deart_disk_1")

#baidu_cases()
modeling_cases()
