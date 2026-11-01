#!/bin/bash
#SBATCH -J shards             # 作业名
#SBATCH -p h100               # 分区：h100 或 h200
#SBATCH -a 0-9%4              # 10 个任务，编号 0–9，最多同时跑 4 个
#SBATCH --gres=gpu:1          # 每个任务的 GPU 数
#SBATCH -c 24                 # 每个任务的 CPU 数，每张卡 24 个
#SBATCH -t 12:00:00           # 每个任务的时间上限
#SBATCH -o %x-%A_%a.out       # 日志：<作业名>-<作业号>_<任务号>.out，写在提交目录

source ~/anaconda3/bin/activate myenv   # 换成自己的 conda 路径和环境
echo "$(date '+%F %T') 任务 $SLURM_ARRAY_TASK_ID 在 $(hostname)，GPU $CUDA_VISIBLE_DEVICES"

python process.py --shard "$SLURM_ARRAY_TASK_ID" --num-shards 10
