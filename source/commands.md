# 常用操作

以下命令都在 login-02 上执行。

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

## 提交和交互

```bash
sbatch job.sbatch                                 # 提交脚本，返回作业号
# 交互式用卡：拿到节点上的 shell，exit 后释放
srun -p h100 --gres=gpu:1 -c 24 -t 2:00:00 --pty bash
srun --jobid <作业号> --overlap --pty bash        # 进入在跑的作业，看 nvidia-smi 等
```

## 取消

```bash
scancel <作业号>
scancel -u $USER                        # 取消自己的全部作业
```

## 注意

1. 作业里的程序能看到整台机器的卡（没有做隔离）。只能用 Slurm 分给你的卡，卡号在 `CUDA_VISIBLE_DEVICES` 里，不要改这个变量。
2. h100-3 的全部卡、h200-1 的 0–3 号卡只通过 Slurm 使用，不要 ssh 上去直接跑。
3. CPU 按卡申请，每张卡 24 个（`-c`）。内存目前不按申请分配，不用写 `--mem`。
4. `-o` 指定的日志目录必须已经存在，否则作业会立即失败，也不会留下日志。模板把日志写在提交目录，没有这个问题。
5. 默认分区是 `h100`，用 H200 要写 `-p h200`。
