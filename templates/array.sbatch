#!/bin/bash
#SBATCH -J shards             # 作业名
#SBATCH -p h100               # 分区：h100 或 h200
#SBATCH -a 0-9%4              # 10 个任务，编号 0–9，最多同时运行 4 个
#SBATCH --gres=gpu:1          # 每个任务的 GPU 数
#SBATCH -c 24                 # 每个任务的 CPU 数：h100 每张 GPU 24 个，h200 每张 GPU 28 个
#SBATCH -t 12:00:00           # 每个任务的时间上限
#SBATCH -o %x-%A_%a.out       # 日志：<作业名>-<作业号>_<任务号>.out，写在提交目录

source ~/miniforge3/bin/activate myenv   # conda 安装在其他路径时换成实际路径
echo "$(date '+%F %T') 任务 $SLURM_ARRAY_TASK_ID 在 $(hostname)，GPU $CUDA_VISIBLE_DEVICES"

python process.py --shard "$SLURM_ARRAY_TASK_ID" --num-shards 10
