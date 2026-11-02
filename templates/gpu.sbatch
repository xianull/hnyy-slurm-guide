#!/bin/bash
#SBATCH -J myjob              # 作业名
#SBATCH -p h100               # 分区：h100 或 h200
#SBATCH --gres=gpu:1          # GPU 数
#SBATCH -c 24                 # CPU 数：h100 每张 GPU 24 个，h200 每张 GPU 28 个
#SBATCH -t 1-00:00:00         # 时间上限（天-时:分:秒），最长 7-00:00:00
#SBATCH -o %x-%j.out          # 日志：<作业名>-<作业号>.out，写在提交目录

source ~/miniforge3/bin/activate myenv   # conda 安装在其他路径时换成实际路径
echo "$(date '+%F %T') 作业 $SLURM_JOB_ID 在 $(hostname)，GPU $CUDA_VISIBLE_DEVICES"

python train.py
