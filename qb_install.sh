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
echo "请运行以下命令以启用和启动qbittorrent-nox服务："
echo "sudo systemctl enable qb.service"
echo "sudo systemctl start qb.service"
