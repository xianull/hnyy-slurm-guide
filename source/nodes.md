# 节点

| 节点 | GPU | CPU | Slurm |
|---|---|---|---|
| h100-1 | 8 × H100 80GB | 96 核 | 未接入 |
| h100-2 | 8 × H100 80GB | 96 核 | 未接入 |
| h100-3 | 8 × H100 80GB | 96 核 | `h100` 分区，8 张卡 |
| h200-1 | 8 × H200 141GB | 112 核 | `h200` 分区，0–3 号卡 |
| h200-2 | 8 × H200 141GB | 112 核 | 未接入 |

- CPU：h100 是 2 × Xeon Platinum 8558，h200 是 2 × Xeon Platinum 8570，每核 2 线程。每台内存 2 TB。
- h200-2 的驱动目前只识别 4 张卡。
- 同一台机器的 GPU 之间两两 NVLink 互联。系统 Ubuntu 22.04，驱动 595.58.03，CUDA 13.2。
- 登录节点：
  - login-01：能上外网，装包、下载在这里做。
  - login-02：Slurm 命令（`sbatch`、`squeue` 等）只在这台上有。
- 共享存储，所有节点看到的是同一份：
  - `/gpfs/flash`（307 TB）：家目录 `/gpfs/flash/home/<用户名>`。
  - `/gpfs/hybrid`（552 TB）：项目目录 `/gpfs/hybrid/projects/<项目名>`。
- Slurm 21.08。单个作业最长 7 天。账号在 `gpu_users` 组里才能提交，用 `id` 查看。
