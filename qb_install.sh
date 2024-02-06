#!/bin/bash

# 第一部分：下载qbittorrent-nox二进制文件并设置权限

# 下载qbittorrent-nox二进制文件，版本为4.4.5
wget -qO /usr/local/bin/qbittorrent-nox "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.4.5_v2.0.8/$(uname -m)-qbittorrent-nox"

# 设置qbittorrent-nox二进制文件的权限为700
chmod 700 /usr/local/bin/qbittorrent-nox

# 第二部分：创建Systemd服务单元文件

# 定义服务单元文件路径
service_file="/etc/systemd/system/qb.service"

# 创建并编辑服务单元文件
cat << EOF > $service_file
[Unit]
Description=qBittorrent Service
After=network.target nss-lookup.target

[Service]
Type=forking
UMask=007
ExecStart=/usr/local/bin/qbittorrent-nox -d --webui-port=12380
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 提示服务单元文件已创建
echo "Systemd服务单元文件已创建：$service_file"

# 启用qbittorrent-nox服务
systemctl enable qb.service

# 启动qbittorrent-nox服务
systemctl start qb.service

# 提示启用和启动服务的命令
echo "qbittorrent-nox服务已启用和启动。"
echo "要停止服务，请运行：sudo systemctl stop qb.service"
echo "要查询服务状态，请运行：sudo systemctl status qb.service"

# 获取本机IP地址
ip_address=$(hostname -I | awk '{print $1}')

# 提示打开qbittorrent的命令
echo "要访问qbittorrent，请在浏览器中打开：http://$ip_address:12380"
