#!/bin/bash

# 检查 Pip 是否安装
if ! command -v pip > /dev/null; then
    echo "pip is not installed. Trying to install pip..."
    sudo apt update && sudo apt install python3-pip
    if [ $? -ne 0 ]; then
        echo "Installation of pip failed. Exiting."
        exit 1
    fi
else
    echo "pip is already installed."
fi

# 安装 autoremove-torrents
echo "Installing autoremove-torrents..."
pip -q install autoremove-torrents
if [ $? -ne 0 ]; then
    echo "Installation of autoremove-torrents failed. Exiting."
    exit 1
fi

# 创建配置文件夹
art_config_folder="/root/.config/autoremove-torrents"
if [ ! -d "$art_config_folder" ]; then
    echo "Creating configuration directory..."
    mkdir -p "$art_config_folder"
fi

# 创建或覆盖 config.yml 文件
art_config_file="${art_config_folder}/config.yml"
echo "Writing to configuration file at ${art_config_file}..."
cat > "$art_config_file" <<EOL
# Your configuration settings go here, for example:
my_task:
  client: qbittorrent
  host: http://127.0.0.1:8080/
  username: admin
  password: adminadmin
  strategies:
    strategy1:
      all_categories: true
      remove: true # Remove torrents immediately
      seeding_time: 120 # Torrents that are seeding longer than 2 hours
EOL

# 检查 autoremove-torrents 的路径，并设置计划任务
echo "Setting up cron job..."
ART_PATH=$(which autoremove-torrents)

( crontab -l 2>/dev/null | grep -v "$ART_PATH"; echo "*/2 * * * * $ART_PATH --conf=${art_config_file}" ) | crontab -

# 检查计划任务是否设置成功
if [ $? -ne 0 ]; then
    echo "Failed to add or update the cron job. Exiting."
    exit 1
fi

echo "autoremove-torrents has been set up successfully and will run every 2 minutes."
