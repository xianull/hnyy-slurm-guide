# 账号和登录

## 开号

向管理员申请账号，提供中文姓名，并说明要使用哪些节点。用户名是姓名全拼。需要通过 Slurm 使用 GPU 的，管理员还须把账号加入 `gpu_users` 组，并同步到 h100-3 和 h200-1：作业以你的账号在这些节点上运行，节点上没有这个账号，作业无法启动。

## 登录

登录节点的地址向管理员获取。在自己电脑的 `~/.ssh/config` 中写入：

```text
Host hnyy-login-01
    HostName <login-01 地址>
    User <用户名>

Host hnyy-login-02
    HostName <login-02 地址>
    User <用户名>

# GPU 节点经 login-02 跳转，用于查看 nvidia-smi、日志等
Host h100-3 h200-1
    ProxyJump hnyy-login-02
    User <用户名>
```

之后用 `ssh hnyy-login-02` 登录。Slurm 命令只在 login-02 上可用，日常使用 login-02 即可。

## 密钥登录

```bash
ssh-keygen -t ed25519          # 在自己电脑上执行，已有密钥跳过
ssh-copy-id hnyy-login-02      # 输入一次密码
```

公钥写入家目录的 `~/.ssh/authorized_keys`。家目录在所有节点共享，这把密钥在所有节点都生效。

## 修改密码

账号是每个节点各自的本地账号，`passwd` 只修改当前节点的密码，其他节点仍是旧密码。用密钥登录可以避开这个问题；需要统一修改所有节点的密码时，找管理员。
