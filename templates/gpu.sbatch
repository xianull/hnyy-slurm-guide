#!/bin/bash
#SBATCH -J myjob              # 作业名
#SBATCH -p h100               # 分区：h100 或 h200
#SBATCH --gres=gpu:1          # GPU 数
#SBATCH -c 24                 # CPU 数，每张卡 24 个
#SBATCH -t 1-00:00:00         # 时间上限（天-时:分:秒），最长 7-00:00:00
#SBATCH -o %x-%j.out          # 日志：<作业名>-<作业号>.out，写在提交目录

source ~/anaconda3/bin/activate myenv   # 换成自己的 conda 路径和环境
echo "$(date '+%F %T') 作业 $SLURM_JOB_ID 在 $(hostname)，GPU $CUDA_VISIBLE_DEVICES"

python train.py
