#!/bin/bash

# 检查 pip 是否安装
if ! command -v pip > /dev/null; then
    echo "pip 未安装，尝试安装 pip..."
    sudo apt-get update -y && sudo apt-get install -y python3-pip
    if [ $? -ne 0 ]; then
        echo "pip 安装失败，退出。"
        exit 1
    fi
else
    echo "pip 已经安装。"
fi

# 安装 autoremove-torrents
echo "正在安装 autoremove-torrents..."
pip -q install autoremove-torrents
if [ $? -ne 0 ]; then
    echo "autoremove-torrents 安装失败，退出。"
    exit 1
fi

# 创建配置文件夹
art_config_folder="/root/.config/autoremove-torrents"
if [ ! -d "$art_config_folder" ]; then
    echo "正在创建配置目录..."
    mkdir -p "$art_config_folder"
fi
# 创建 autoremove-torrents 的 logs 目录
art_log_folder="/root/.config/autoremove-torrents/logs"
mkdir -p $art_log_folder

# 创建或覆盖 config.yml 文件
art_config_file="${art_config_folder}/config.yml"
echo "正在写入配置文件到 ${art_config_file}..."
cat > "$art_config_file" <<EOL
qb_task:
  client: qbittorrent
  host: http://127.0.0.1:12380/
  username: admin
  password: adminadmin
  strategies:
    Disk:
      free_space:
        min: 2
        path: /root/
        action: remove-old-seeds
  delete_data: true
EOL

# 检查 autoremove-torrents 的路径，并设置计划任务
echo "正在设置计划任务..."
art_path=$(which autoremove-torrents)

( crontab -l 2>/dev/null | grep -v "$art_path"; echo "*/2 * * * * $art_path --conf=${art_config_file} --log=${art_log_folder}" ) | crontab -

# 检查计划任务是否设置成功
if [ $? -ne 0 ]; then
    echo "添加或更新计划任务失败，退出。"
    exit 1
fi

echo "autoremove-torrents 设置成功，将每 2 分钟运行一次。"
