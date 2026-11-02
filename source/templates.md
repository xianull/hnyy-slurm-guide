# 提交模板

仓库的 `templates/` 下有四个模板。复制一份，修改 `#SBATCH` 行、conda 环境和最后一行命令，再提交。建环境的方法见 {doc}`env`，`-c` 的取值见 {ref}`申请多少资源 <resources>`。

```bash
cp templates/gpu.sbatch myjob.sbatch    # 修改后提交
sbatch myjob.sbatch
```

| 模板 | 用途 |
|---|---|
| [`gpu.sbatch`](#gpu-sbatch) | 单 GPU 作业：训练、推理脚本 |
| [`multi_gpu.sbatch`](#multi-gpu-sbatch) | 单节点多 GPU 训练（torchrun） |
| [`serve.sbatch`](#serve-sbatch) | 长期运行的模型服务（vLLM），用 `scancel` 停止 |
| [`array.sbatch`](#array-sbatch) | 一批相同的任务（作业数组），例如每个数据分片一个任务 |

(gpu-sbatch)=
## gpu.sbatch：单 GPU 作业

```{literalinclude} ../templates/gpu.sbatch
:language: bash
```

(multi-gpu-sbatch)=
## multi_gpu.sbatch：单节点多 GPU 训练

```{literalinclude} ../templates/multi_gpu.sbatch
:language: bash
```

(serve-sbatch)=
## serve.sbatch：模型服务

日志第一行是服务地址。在 login-02 或其他节点上访问：`curl http://h100-3:8000/v1/models`。

```{literalinclude} ../templates/serve.sbatch
:language: bash
```

(array-sbatch)=
## array.sbatch：作业数组

整体取消用 `scancel <作业号>`，只取消 3 号任务用 `scancel <作业号>_3`。

```{literalinclude} ../templates/array.sbatch
:language: bash
```
