# 常用操作

以下命令都在 login-02 上执行。

(resources)=
## 申请多少资源

CPU 按 GPU 数申请：

| GPU 数 | h100 分区 `-c` | h200 分区 `-c` |
|---|---|---|
| 1 | 24 | 28 |
| 2 | 48 | 56 |
| 4 | 96 | 112 |
| 8 | 192 | — |

这个比例是整个节点的 CPU 按 GPU 数平分的结果：h100 节点有 192 个 CPU、8 张 GPU，每张 24 个；h200 节点有 224 个 CPU、8 张 GPU，每张 28 个。h200-1 只有 0–3 号 GPU 由 Slurm 管理，4–7 号 GPU 的使用者同样需要 CPU，所以 h200 分区的作业合计不应超过 112 个 CPU。Slurm 不强制这个比例，多占的 CPU 会让后面的作业排队等待。

- `-c` 数的是 CPU（每个物理核 2 个）。Slurm 按整核分配，奇数会向上补成偶数，例如 `-c 3` 实际分配 4 个。
- 不用 GPU 的纯 CPU 作业（不写 `--gres`）占用的是 GPU 作业的 CPU，`-c` 应尽量小。
- 内存不按申请分配，不用写 `--mem`。按 GPU 数平分约每张 250 GB，用量远超这个数会影响同一节点上的其他作业。
- `-t` 应接近实际用时：调度采用回填，用时短的作业可以提前开始。

## 查看

```bash
# 节点和 GPU：GresUsed 一列的 gpu:gpufull:4(IDX:0-3) 表示 0–3 号 GPU 已被占用
sinfo -N -O "NodeList:10,Partition:8,Gres:16,GresUsed:26,CPUsState:16"
squeue                                  # 排队和运行中的作业
squeue -u $USER                         # 只看自己的
scontrol show job <作业号>              # 作业详情：排队原因、所在节点、分配的 GPU
# 已结束的作业：状态、退出码、用时
sacct -j <作业号> -X -o JobID,JobName,State,ExitCode,Elapsed,NodeList
tail -f <作业名>-<作业号>.out           # 日志
```

`CPUsState` 一列是 `已分配/空闲/其他/总数`。

(gpu-usage)=
## 查看 GPU 使用率

GPU 节点不开放 ssh 登录，查看 GPU 也通过 Slurm。`<作业号>` 换成自己正在运行的作业：

| 查看内容 | 命令 |
|---|---|
| 整个节点的 8 张 GPU，包括其他用户的作业 | `srun -p h100 -n 1 -t 1 nvidia-smi`（h200 分区改成 `-p h200`） |
| 自己的作业分配到的 GPU | `srun --jobid <作业号> --overlap bash -c 'nvidia-smi -i $CUDA_VISIBLE_DEVICES'` |
| 自己的作业分配到的 GPU，每 2 秒刷新 | `srun --jobid <作业号> --overlap --pty bash -c 'watch -n 2 nvidia-smi -i $CUDA_VISIBLE_DEVICES'` |
| 自己的作业分配到的 GPU，每秒输出一行 | `srun --jobid <作业号> --overlap bash -c 'nvidia-smi dmon -s um -i $CUDA_VISIBLE_DEVICES'` |
| Slurm 分配了哪些 GPU | `sinfo -N -O NodeList:10,Gres:20,GresUsed:28` |

- 第一条不需要自己有作业。它占 2 个 CPU（1 个物理核），最长 1 分钟，不占 GPU；节点的 CPU 全部分配完时会排队。
- 中间三条用 `--overlap` 在作业已分配的资源上运行，不用排队。Ctrl-C 只结束这条命令，作业继续运行。
- 单引号不能省：`$CUDA_VISIBLE_DEVICES` 须在 GPU 节点上展开，在 login-02 上它是空的。去掉 `-i $CUDA_VISIBLE_DEVICES` 时显示节点上全部 8 张 GPU。
- 最后一条是 Slurm 的分配记录，不是实际占用。
- GPU-Util 是采样周期内 GPU 上有 CUDA kernel 运行的时间比例，100% 不代表算力用满。`dmon` 输出中，`sm` 列即 GPU-Util，`fb` 列是显存用量（MB），`mem` 列是显存带宽的使用率。
- 训练时 GPU-Util 长时间偏低，常见原因是数据加载跟不上。可以调大 DataLoader 的 `num_workers`，`num_workers` 乘以 GPU 数不超过 `-c`。

## 提交和交互

```bash
sbatch job.sbatch                                 # 提交脚本，返回作业号
# 交互式使用 GPU：获得节点上的 shell，exit 后释放
srun -p h100 --gres=gpu:1 -c 24 -t 2:00:00 --pty bash
srun -p h200 --gres=gpu:1 -c 28 -t 2:00:00 --pty bash
srun --jobid <作业号> --overlap --pty bash        # 进入运行中的作业，查看 nvidia-smi 等
```

`srun` 和 `sbatch` 把当前 shell 的环境变量带到节点上。先 `conda activate` 再 `srun python ...`，节点上使用的就是这个环境。

## 取消

```bash
scancel <作业号>
scancel -u $USER                        # 取消自己的全部作业
```

## 注意

作业出错时先看{doc}`troubleshoot`。

1. 作业中的程序能看到整个节点的 GPU（没有隔离）。只能使用 Slurm 分配的 GPU，编号在环境变量 `CUDA_VISIBLE_DEVICES` 中，不要修改这个变量。
2. `-o` 指定的日志目录须已存在，否则作业立即失败，也不留下日志。模板把日志写在提交目录，没有这个问题。
3. 默认分区是 `h100`，使用 H200 须写 `-p h200`。
4. `docker run` 启动的容器不由 Slurm 管理：`scancel` 无法停止它，作业达到时间上限时它也不会结束，须自己 `docker stop`。
