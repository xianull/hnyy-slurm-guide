#!/bin/bash
#SBATCH -J vllm               # 作业名
#SBATCH -p h100               # 分区：h100 或 h200
#SBATCH --gres=gpu:2          # GPU 数，也是下面的张量并行数
#SBATCH -c 48                 # CPU 数：h100 每张 GPU 24 个，h200 每张 GPU 28 个
#SBATCH -t 7-00:00:00         # 时间上限，到达后服务被终止；提前停止用 scancel
#SBATCH -o %x-%j.out          # 日志：<作业名>-<作业号>.out，写在提交目录

source ~/miniforge3/bin/activate myenv   # conda 安装在其他路径时换成实际路径；myenv 换成安装了 vLLM 的环境
MODEL=/gpfs/flash/data/models/Qwen3-32B  # 模型目录
PORT=8000                               # 端口被占用时换一个，先在节点上查：ss -ltn | grep :8000
NGPU=$(awk -F, '{print NF}' <<< "$CUDA_VISIBLE_DEVICES")
echo "$(date '+%F %T') 作业 $SLURM_JOB_ID，GPU $CUDA_VISIBLE_DEVICES，加载完成后的地址：http://$(hostname -s):$PORT/v1"

exec vllm serve "$MODEL" --served-model-name "$(basename "$MODEL")" --tensor-parallel-size "$NGPU" \
  --host 0.0.0.0 --port "$PORT"
