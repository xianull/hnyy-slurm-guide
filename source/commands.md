# 常用操作

以下命令都在 login-02 上执行。

(resources)=
## 申请多少资源

CPU 按卡数申请：

| GPU 数 | h100 分区 `-c` | h200 分区 `-c` |
|---|---|---|
| 1 | 24 | 28 |
| 2 | 48 | 56 |
| 4 | 96 | 112 |
| 8 | 192 | — |

- 比例来自整机平分：h100 有 192 个逻辑 CPU、8 张卡，每张卡 24 个；h200 有 224 个、8 张卡，每张卡 28 个。h200-1 只有 0–3 号卡归 Slurm，4–7 号卡的使用者也要用 CPU，所以 h200 分区的作业合计不超过 112 个。
- Slurm 不强制这个比例，要靠大家遵守。多占的 CPU 会让后面的作业排不上。
- `-c` 数的是逻辑 CPU（每核 2 个线程）。Slurm 按整核分配，写奇数会向上补成偶数，例如 `-c 3` 实际分到 4 个。
- 不用 GPU 的纯 CPU 作业（不写 `--gres`）占的是 GPU 作业的 CPU，`-c` 尽量写小。
- 内存不按申请分配，不用写 `--mem`。按卡平分大约每张卡 250 GB，用得太多会挤到同机器上的其他作业。
- `-t` 写接近实际的用时。调度器会把用时短的作业插到空档里先跑。

## 查看

```bash
# 节点和卡：GresUsed 一列的 gpu:gpufull:4(IDX:0-3) 表示 0–3 号卡已被占用
sinfo -N -O "NodeList:10,Partition:8,Gres:16,GresUsed:26,CPUsState:16"
squeue                                  # 排队和在跑的作业
squeue -u $USER                         # 只看自己的
scontrol show job <作业号>              # 作业详情：排队原因、在哪台、哪几张卡
# 结束的作业：状态、退出码、用时
sacct -j <作业号> -X -o JobID,JobName,State,ExitCode,Elapsed,NodeList
tail -f <作业名>-<作业号>.out           # 日志
```

`CPUsState` 一列是 `已分配/空闲/其他/总数`。

## 提交和交互

```bash
sbatch job.sbatch                                 # 提交脚本，返回作业号
# 交互式用卡：拿到节点上的 shell，exit 后释放
srun -p h100 --gres=gpu:1 -c 24 -t 2:00:00 --pty bash
srun -p h200 --gres=gpu:1 -c 28 -t 2:00:00 --pty bash
srun --jobid <作业号> --overlap --pty bash        # 进入在跑的作业，看 nvidia-smi 等
```

`srun` 和 `sbatch` 会把当前 shell 的环境变量带到节点上。先 `conda activate` 再 `srun python ...`，节点上用的就是这个环境。

## 取消

```bash
scancel <作业号>
scancel -u $USER                        # 取消自己的全部作业
```

## 注意

1. 作业里的程序能看到整台机器的卡（没有做隔离）。只能用 Slurm 分给你的卡，卡号在 `CUDA_VISIBLE_DEVICES` 里，不要改这个变量。
2. h100-3 的全部卡、h200-1 的 0–3 号卡只通过 Slurm 使用，不要 ssh 上去直接跑。
3. `-o` 指定的日志目录必须已经存在，否则作业会立即失败，也不会留下日志。模板把日志写在提交目录，没有这个问题。
4. 默认分区是 `h100`，用 H200 要写 `-p h200`。
5. `docker run` 起的容器不归 Slurm 管：`scancel` 停不掉它，作业到时间了它也不会结束，要自己 `docker stop`。
