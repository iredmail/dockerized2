# 准备 docker 版需要的文件

## 获取要安装的软件包列表

- 为 Linux AMD64 平台编译 Pro 仓库里的 `cmd/cli/`，得到 `bin/gosible`。
- 新建一个 `settings.json` 文件
    - 定义变量 `iredmail_backend` 设置 backend
    - 定义变量 `use_XXX` 启用各个组件
- 运行一个 Ubuntu 22.04 系统，将 `gosible` 和 `settings.json` 复制进去，运行
  以下命令得到指定的 backend 需要安装的软件包列表：

```
./gosible -e settings.json -p print_pkgs.yml
```

    修改 `settings.json` 文件里的 `iredmail_backend` 变量，更换为其它 backend，
    重复以上步骤得到其它 backend 要安装的软件包列表。

- 将得到的软件包列表更新到 `install_all_pkgs.sh` 脚本里。
- 检查 `install_all_pkgs.sh` 文件顶部定义的几个软件包是否有新版本，有则更新之。
