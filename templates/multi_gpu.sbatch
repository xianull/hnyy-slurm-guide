#!/bin/bash
#SBATCH -J ddp                # 作业名
#SBATCH -p h100               # 分区：h100 或 h200
#SBATCH --gres=gpu:4          # GPU 数
#SBATCH -c 96                 # CPU 数：h100 每张 GPU 24 个，h200 每张 GPU 28 个
#SBATCH -t 3-00:00:00         # 时间上限，最长 7-00:00:00
#SBATCH -o %x-%j.out          # 日志：<作业名>-<作业号>.out，写在提交目录

source ~/miniforge3/bin/activate myenv   # conda 安装在其他路径时换成实际路径
NGPU=$(awk -F, '{print NF}' <<< "$CUDA_VISIBLE_DEVICES")
echo "$(date '+%F %T') 作业 $SLURM_JOB_ID 在 $(hostname)，GPU $CUDA_VISIBLE_DEVICES（$NGPU 张）"

# torchrun 默认把每个进程的线程数设为 1，这里按每张 GPU 分到的 CPU 数设置
export OMP_NUM_THREADS=$((SLURM_CPUS_PER_TASK / NGPU))
# --standalone 自动选择空闲端口，同一节点上的两个作业不会冲突
torchrun --standalone --nproc_per_node="$NGPU" train.py
