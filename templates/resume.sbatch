#!/bin/bash
#SBATCH -J resume             # 作业名
#SBATCH -p h100               # 分区：h100 或 h200
#SBATCH --gres=gpu:1          # GPU 数
#SBATCH -c 24                 # CPU 数：h100 每张 GPU 24 个，h200 每张 GPU 28 个
#SBATCH -t 7-00:00:00         # 每一段的时间上限，最长 7-00:00:00
#SBATCH --signal=B:USR1@600   # 到达时间上限前 600 秒，向脚本发送 SIGUSR1
#SBATCH -o %x-%j.out          # 日志：<作业名>-<作业号>.out，写在提交目录

source ~/miniforge3/bin/activate myenv   # conda 安装在其他路径时换成实际路径
echo "$(date '+%F %T') 作业 $SLURM_JOB_ID 在 $(hostname)，GPU $CUDA_VISIBLE_DEVICES"

# exec 让 python 取代当前 shell，直接收到 SIGUSR1；train.py 收到后保存 checkpoint 并退出
exec python train.py
