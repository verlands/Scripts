#!/bin/bash

################################################
###
###     安装 qbittorrent-nox 并设置守护进程
###
################################################

# 下载qbittorrent-nox二进制文件并设置权限

# 下载qbittorrent-nox二进制文件，版本为4.4.5
# 4.4.0及以后版本吃配置，上传慢，推荐4.3.8/9，更稳定，内存占用更小
wget -qO /usr/local/bin/qbittorrent-nox "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.3.9_v1.2.15/$(uname -m)-qbittorrent-nox"

# 设置qbittorrent-nox二进制文件的权限为700
chmod 700 /usr/local/bin/qbittorrent-nox

# 创建Systemd服务单元文件，即 qbittorrent 守护进程

# 定义服务单元文件路径
service_file="/etc/systemd/system/qb.service"

# 创建并编辑服务单元文件
# cat << EOF > $service_file 这行不知道有没有问题
sudo tee $service_file <<EOF
[Unit]
Description=qBittorrent Daemon Service
After=network.target

[Service]
Type=forking
User=root
ExecStart=/usr/local/bin/qbittorrent-nox -d --webui-port=12380
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 设置qb.service文件的权限为644
# chmod 644 $service_file

# 提示服务单元文件已创建
echo "Systemd服务单元文件已创建：$service_file"




################################################
###
###     安装 autobrr 并设置守护进程
###
################################################

# 下载autobrr
wget $(curl -s https://api.github.com/repos/autobrr/autobrr/releases/latest | grep download | grep linux_x86_64 | cut -d\" -f4)

# 解压 autobrr 和 autobrrctl 到 /usr/local/bin，如果不是root用户，可以解压到 ~/.bin 目录内
sudo tar -C /usr/local/bin -xzf autobrr*.tar.gz

# 创建配置目录
mkdir -p ~/.config/autobrr

# 配置文件
CONFIG_FILE="~/.config/autobrr/config.toml"
curl -o $CONFIG_FILE -L https://raw.githubusercontent.com/autobrr/autobrr/develop/config.toml
# 修改配置文件，使得可以远程连接
sudo sed -i 's/host = "127.0.0.1"/host = "0.0.0.0"/' $CONFIG_FILE
sudo sed -i 's/port = 7474/port = 12381/' $CONFIG_FILE

# 创建 systemd 服务文件
AUTOBRR_SERVICE=/etc/systemd/system/autobrr.service
sudo tee $AUTOBRR_SERVICE <<EOF
[Unit]
Description=autobrr daemon
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/autobrr --config=/root/.config/autobrr/
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 提示服务单元文件已创建
echo "Systemd服务单元文件已创建：$AUTOBRR_SERVICE"

# 更新配置
systemctl daemon-reload

# 启用qbittorrent-nox服务
systemctl enable qb.service
systemctl enable autobrr

# 启动qbittorrent-nox服务
systemctl start qb.service
systemctl start autobrr

# 提示启用和启动服务的命令
echo "qbittorrent-nox服务已启用和启动。"
echo "要停止服务，请运行：sudo systemctl stop qb.service"
echo "要查询服务状态，请运行：sudo systemctl status qb.service"

# 获取本机IP地址
ip_address=$(hostname -I | awk '{print $1}')

# 提示打开qbittorrent的命令
echo "要访问qbittorrent，请在浏览器中打开：http://$ip_address:12380"
echo "要访问 autobrr，请在浏览器中打开：http://$ip_address:12381"



