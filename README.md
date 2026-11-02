# HNYY 集群 Slurm 使用指南

网页版：https://xianull.github.io/hnyy-slurm-guide/ （推送到 main 后由 GitHub Actions 自动构建发布）

| 页面 | 内容 |
|---|---|
| [`source/nodes.md`](source/nodes.md) | 节点配置：处理器、GPU、CPU 亲和性、本地盘、网络、软件、登录节点、存储、Slurm 分区 |
| [`source/env.md`](source/env.md) | 环境配置：conda、国内源、编译 CUDA 扩展、下载模型 |
| [`source/commands.md`](source/commands.md) | 申请多少资源（GPU 与 CPU 的比例）、Slurm 常用操作和注意事项 |
| [`source/templates.md`](source/templates.md) | 提交模板说明，模板文件在 [`templates/`](templates/) |

本地预览：

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt   # 只需一次
.venv/bin/sphinx-build -b html source build/html   # 打开 build/html/index.html
```
