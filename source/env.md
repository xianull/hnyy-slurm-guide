# 环境配置

环境在登录节点安装一次，所有节点都能使用。所有节点挂载同一个 GPFS，家目录 `/gpfs/flash/home/<用户名>` 在每个节点上都是同一份，安装在家目录里的 conda 环境因此在每个节点上都可见。登录节点和 GPU 节点的系统、CUDA 工具包版本相同（Ubuntu 22.04，CUDA 13.2），五台 GPU 节点的驱动也相同，同一个环境可以在任一节点上运行。GPU 节点无法访问外网，安装和下载只能在登录节点（login-01 或 login-02）完成。

## 1. 安装 conda（只需一次）

已安装 miniconda 或 anaconda 的用户跳过此步，并把后面命令中的 `~/miniforge3` 换成自己的安装路径。

```bash
wget https://mirrors.tuna.tsinghua.edu.cn/github-release/conda-forge/miniforge/LatestRelease/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p ~/miniforge3
~/miniforge3/bin/conda init bash    # 写入 ~/.bashrc，重新登录后在每个节点生效
```

Miniforge 默认使用免费的 conda-forge 源，Anaconda 官方源对规模较大的机构收费。`/gpfs/flash/software/anaconda` 是一份所有用户都有写权限的公共 anaconda，任何人都能修改其中的文件，不要把自己的环境建在里面。

## 2. 换国内源（只需一次）

```bash
conda config --set custom_channels.conda-forge https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

配置写入 `~/.condarc` 和 `~/.config/pip/pip.conf`，同样在每个节点生效。

## 3. 建环境

```bash
conda create -n myenv python=3.12 -y
conda activate myenv
pip install torch                  # PyPI 上默认的 torch 是 CUDA 13 版本，驱动支持
pip install -r requirements.txt
```

驱动最高支持 CUDA 13.2，CUDA 12.x 和 13.x 版本的 torch 都可以使用。

## 4. 在 GPU 上验证

在 login-02 上执行：

```bash
conda activate myenv
srun -p h100 --gres=gpu:1 -c 24 -t 10 python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

输出 `True NVIDIA H100 80GB HBM3` 说明环境可用。

## 5. 编译 CUDA 扩展（flash-attn 等）

优先使用预编译的 wheel，没有时再自己编译。编译不需要 GPU，在登录节点完成：

```bash
export CUDA_HOME=/usr/local/cuda   # CUDA 13.2，与默认 torch 的 CUDA 主版本一致
export TORCH_CUDA_ARCH_LIST=9.0    # H100、H200 都是 9.0，只编译这一种架构，缩短编译时间
export MAX_JOBS=8                  # 登录节点由所有用户共用，限制并行编译的进程数
pip install flash-attn --no-build-isolation
```

项目固定使用 CUDA 12 版本的 torch 时，与系统的 CUDA 13.2 版本不一致，须在环境中另行安装同版本的 CUDA 工具包，再把 `CUDA_HOME` 指向它。

## 6. 下载模型和数据

GPU 节点无法访问外网，模型须先在登录节点下载。

1. 先在公共模型目录 `/gpfs/flash/data/models` 中查找。
2. huggingface.co 无法访问，用镜像下载到项目目录：
   ```bash
   pip install -U huggingface_hub
   export HF_ENDPOINT=https://hf-mirror.com
   hf download Qwen/Qwen3-8B --local-dir /gpfs/hybrid/projects/<项目名>/models/Qwen3-8B
   ```
3. 作业中按本地路径加载模型，并设置 `export HF_HUB_OFFLINE=1`，禁止程序联网检查更新。

## 注意

1. 作业运行期间，不要修改它正在使用的环境（升级、卸载包）。所有节点读取的是同一份文件，修改立即影响运行中的作业。需要测试新版本时，先克隆一份：`conda create -n myenv2 --clone myenv`。
2. 作业脚本中用 `source ~/miniforge3/bin/activate myenv` 激活环境。sbatch 脚本不读取 `~/.bashrc`，直接写 `conda activate` 可能报错。
3. 环境和缓存都算在家目录的 200 GB 里。pip 和 conda 的缓存持续增长，安装一次 torch 就有数 GB，应定期清理：`pip cache purge`、`conda clean -a -y`。不再使用的环境用 `conda env remove -n <环境名>` 删除。
4. Hugging Face 的缓存默认在 `~/.cache/huggingface`，下载的模型会占满家目录。在 `~/.bashrc` 中把它指到项目目录：`export HF_HOME=/gpfs/hybrid/projects/<项目名>/<用户名>/hf_cache`。
