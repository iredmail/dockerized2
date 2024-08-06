- pgsql 版：
    - 改进 entrypoing.sh，等待 pgsql 服务起来
    - 测试容器运行情况

# 单容器架构

- 将 EE 运行在一个 Ubuntu 24.04 的容器内部，预先安装好所有组件，EE 负责启用。
- 每次启动容器都调用 gosible 重新生成配置文件（预计比较耗时，需要评估）

# 多容器架构

- 用一个精简的容器来跑 EE 二进制程序，例如 AlpineLinux 容器。
- 启动 EE 容器时挂载 Docker socket，EE 连到 socket 去管理 iRedMail 相关容器。
- EE 负责生成 docker-compose.yml 文件，里头定义使用的容器、mounts、环境变量等。
