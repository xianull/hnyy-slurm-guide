# 排错

## 作业状态

`squeue` 的 `ST` 列和 `sacct` 的 `State` 列：

| ST | State | 含义 |
|---|---|---|
| PD | PENDING | 排队中 |
| R | RUNNING | 运行中 |
| CG | COMPLETING | 正在结束 |
| CD | COMPLETED | 脚本退出码为 0 |
| F | FAILED | 脚本退出码不为 0 |
| TO | TIMEOUT | 达到时间上限，被终止 |
| CA | CANCELLED | 被 `scancel` 取消 |
| NF | NODE_FAIL | 节点故障 |

COMPLETED 只说明脚本最后一条命令的退出码为 0，中间的命令失败了也可能显示 COMPLETED，须查看日志确认。

## 排队原因

`squeue` 最后一列括号里是作业排队的原因：

| 原因 | 含义 | 处理 |
|---|---|---|
| Resources | 空闲的 GPU 或 CPU 不够 | 等待，或减少 GPU 数和 `-c` |
| Priority | 前面有更早提交的作业在排队 | 等待；`-t` 越短，越容易被回填提前开始 |
| Dependency | 依赖的作业还没结束 | 无需处理 |
| DependencyNeverSatisfied | 依赖的作业已结束，但状态不满足条件，例如 `afterok` 依赖的作业失败了 | `scancel` 后重新提交 |
| PartitionTimeLimit | `-t` 超过分区上限 7 天 | 不会自动开始，`scancel` 后改小 `-t` 重新提交 |
| ReqNodeNotAvail | 节点不可用（维护或故障） | 找管理员 |

## 常见问题

### 作业立即结束，没有日志

`-o` 指定的目录不存在。先 `mkdir` 再提交。

### 日志里报 conda activate 错误

报错是 `CondaError: Run 'conda init' before 'conda activate'` 或 `conda: command not found`。sbatch 脚本不读取 `~/.bashrc`，`conda activate` 不可用。改用 `source ~/miniforge3/bin/activate myenv`。这个错误不会让作业失败：脚本继续执行，用的是 base 环境或系统的 python，作业状态仍是 COMPLETED。

### 日志迟迟没有输出

Python 的输出写入文件时有缓冲，缓冲区满后才写入。用 `python -u` 运行，或在脚本中 `export PYTHONUNBUFFERED=1`。

### 报 CUDA out of memory，但程序本身显存用量不大

分配的 GPU 可能被 Slurm 之外的进程占用。用 `srun --jobid <作业号> --overlap nvidia-smi` 查看显存占用，确认后找管理员。

### `srun` 的命令运行了两遍

写了 `-c 1`、没写 `-n` 时出现。Slurm 按整核分配，`-c 1` 实际分配 2 个 CPU；`srun` 不写 `-n` 时，启动的进程数是分配的 CPU 数除以 `-c`，即 2 个。加 `-n 1`，或写 `-c 2`。

### 作业状态为 TIMEOUT

调大 `-t`（最长 `7-00:00:00`），超过 7 天的训练用断点续训，见{doc}`long`。

### 提交时报分区权限错误

报错是 `User's group not permitted to use this partition`：账号不在 `gpu_users` 组，找管理员。

### 查看作业的内存和 CPU 用量

集群没有开启资源用量统计，`sacct` 的 MaxRSS 等字段为空。作业运行期间用 `srun --jobid <作业号> --overlap top -b -n 1 -u $USER` 查看。

### ssh 断开后，交互式 `srun` 作业也结束了

`srun --pty` 绑定当前终端。在登录节点上先开 `tmux`，在 tmux 里运行 `srun`；断开后用 `tmux attach` 回到原来的会话。tmux 会话只存在于启动它的登录节点上。
