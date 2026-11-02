# 环境配置

在登录节点装一次环境，所有节点都能用。原因有三条：

1. 所有节点挂的是同一个 GPFS，家目录 `/gpfs/flash/home/<用户名>` 在每台机器上都是同一份。conda 装在家目录里，每台节点看到的都是同一个环境。
2. 登录节点和 GPU 节点的系统、CUDA 工具包版本相同（Ubuntu 22.04，CUDA 13.2），五台 GPU 节点的驱动也相同，同一个环境在哪台都能跑。
3. GPU 节点不能上外网，装包、下载只能在登录节点（login-01 或 login-02）做。

## 1. 安装 conda（只需一次）

已经装过 miniconda 或 anaconda 的跳过这一步，后面命令里的 `~/miniforge3` 换成自己的路径。

```bash
wget https://mirrors.tuna.tsinghua.edu.cn/github-release/conda-forge/miniforge/LatestRelease/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p ~/miniforge3
~/miniforge3/bin/conda init bash    # 写进 ~/.bashrc，重新登录后每台节点都生效
```

- Miniforge 默认用免费的 conda-forge 源。Anaconda 官方源对规模较大的机构收费。
- `/gpfs/flash/software/anaconda` 是一份所有人都能写的公共 anaconda，谁都可能改动它，不要把自己的环境建在里面。

## 2. 换国内源（只需一次）

```bash
conda config --set custom_channels.conda-forge https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

配置写在 `~/.condarc` 和 `~/.config/pip/pip.conf`，同样在每台节点都生效。

## 3. 建环境

```bash
conda create -n myenv python=3.12 -y
conda activate myenv
pip install torch                  # PyPI 上默认的 torch 是 CUDA 13 版本，驱动支持
pip install -r requirements.txt
```

驱动最高支持 CUDA 13.2，CUDA 12.x 和 13.x 的 torch 都能用。

## 4. 在 GPU 上验证

在 login-02 上：

```bash
conda activate myenv
srun -p h100 --gres=gpu:1 -c 24 -t 10 python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

输出 `True NVIDIA H100 80GB HBM3` 就说明环境可用。

## 5. 编译 CUDA 扩展（flash-attn 等）

先找有没有预编译好的 wheel，没有再自己编译。编译不需要 GPU，在登录节点上做：

```bash
export CUDA_HOME=/usr/local/cuda   # CUDA 13.2，和默认 torch 的 CUDA 主版本一致
export TORCH_CUDA_ARCH_LIST=9.0    # H100、H200 都是 9.0，只编这一种，快很多
export MAX_JOBS=8                  # 登录节点是共用的，限制并行编译的进程数
pip install flash-attn --no-build-isolation
```

如果项目固定用 CUDA 12 的 torch，系统的 CUDA 13.2 对不上，要在环境里另装同版本的 CUDA 工具包，再把 `CUDA_HOME` 指向它。

## 6. 下载模型和数据

GPU 节点不能上外网，模型要先在登录节点下好。

1. 先看公共模型目录 `/gpfs/flash/data/models` 里有没有。
2. huggingface.co 连不上，用镜像下载，放到项目目录：
   ```bash
   pip install -U huggingface_hub
   export HF_ENDPOINT=https://hf-mirror.com
   hf download Qwen/Qwen3-8B --local-dir /gpfs/hybrid/projects/<项目名>/models/Qwen3-8B
   ```
3. 作业里按本地路径加载，并设 `export HF_HUB_OFFLINE=1`，不让程序去联网检查更新。

## 注意

1. 作业在跑时，不要改它正在用的环境（升级、卸载包）。所有节点用的是同一份文件，改动会立即影响正在跑的作业。要试新版本，先复制一份：`conda create -n myenv2 --clone myenv`。
2. 作业脚本里用 `source ~/miniforge3/bin/activate myenv` 激活环境。sbatch 脚本不读 `~/.bashrc`，直接写 `conda activate` 可能报错。
3. 缓存会越来越大（装一次 torch 就是几 GB），定期清理：`pip cache purge`、`conda clean -a -y`。
