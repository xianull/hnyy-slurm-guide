# 长任务和交互式开发

## 超过 7 天的任务：断点续训

单个作业最长 7 天。训练要更久时，把它拆成几段作业：每段从最新的 checkpoint 继续，后一段在前一段结束后自动开始。

模板 `templates/resume.sbatch` 在时间上限前 10 分钟向程序发送 `SIGUSR1`，程序收到后保存 checkpoint 并退出：

```{literalinclude} ../templates/resume.sbatch
:language: bash
```

`train.py` 里处理这个信号，并在启动时读取最新的 checkpoint：

```python
import signal

stop = False
def on_usr1(*_):
    global stop
    stop = True
signal.signal(signal.SIGUSR1, on_usr1)

step = load_latest_checkpoint()      # 自己实现：没有 checkpoint 时返回 0
while step < total_steps and not stop:
    train_one_step()
    step += 1
    if step % 1000 == 0:
        save_checkpoint(step)
save_checkpoint(step)
```

一次提交三段，每段在前一段结束后开始（`afterany`：不论前一段是正常结束还是超时）：

```bash
jid=$(sbatch --parsable resume.sbatch)
for i in 2 3; do jid=$(sbatch --parsable --dependency=afterany:$jid resume.sbatch); done
squeue -u $USER                       # 后两段显示 PD (Dependency)
```

训练提前完成时，后面的作业读到最终的 checkpoint，`step < total_steps` 不成立，立即退出。

多 GPU 训练用 torchrun 启动时，`SIGUSR1` 会直接终止 torchrun（作业显示 FAILED，退出码 0:10），worker 来不及保存，不能用这个模板的信号方式。改为按固定步数保存 checkpoint，同样用 `--dependency` 续跑，每段最多损失一个保存间隔的进度。

## VS Code

VS Code 的 Remote-SSH 连接 login-02，在登录节点上编辑代码。GPU 程序在 VS Code 的终端里用 `srun` 或 `sbatch` 运行。

不要用 VS Code 直接连到 GPU 节点运行程序：经 ssh 启动的进程不属于任何作业，Slurm 不会把它用的 GPU 记为已占用，可能再分配给别的作业。

## Jupyter

Jupyter 在作业里运行，自己电脑经登录节点转发端口访问。

1. 环境里安装 jupyterlab：`pip install jupyterlab`。
2. 在 login-02 上提交：
   ```bash
   conda activate myenv
   sbatch -p h100 --gres=gpu:1 -c 24 -t 8:00:00 -J jupyter -o %x-%j.out \
     --wrap "jupyter lab --no-browser --ip=0.0.0.0 --port=8888"
   ```
3. 用 `squeue -u $USER` 查看作业所在的节点，日志 `jupyter-<作业号>.out` 里有带 token 的访问地址。
4. 在自己电脑上转发端口（`h100-3` 换成作业所在的节点）：
   ```bash
   ssh -N -L 8888:h100-3:8888 hnyy-login-02
   ```
5. 浏览器打开日志里的地址，把主机名换成 `localhost`。

端口 8888 被同一节点上的其他程序占用时，第 2 步和第 4 步换一个端口。用完 `scancel` 结束作业，释放 GPU。
