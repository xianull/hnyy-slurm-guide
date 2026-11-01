#!/bin/bash
#SBATCH -J ddp                # 作业名
#SBATCH -p h100               # 分区：h100 或 h200
#SBATCH --gres=gpu:4          # GPU 数
#SBATCH -c 96                 # CPU 数，每张卡 24 个
#SBATCH -t 3-00:00:00         # 时间上限，最长 7-00:00:00
#SBATCH -o %x-%j.out          # 日志：<作业名>-<作业号>.out，写在提交目录

source ~/anaconda3/bin/activate myenv   # 换成自己的 conda 路径和环境
NGPU=$(awk -F, '{print NF}' <<< "$CUDA_VISIBLE_DEVICES")
echo "$(date '+%F %T') 作业 $SLURM_JOB_ID 在 $(hostname)，GPU $CUDA_VISIBLE_DEVICES（$NGPU 张）"

# --standalone 自己选一个空闲端口，同一台机器上的两个作业不会冲突
torchrun --standalone --nproc_per_node="$NGPU" train.py
