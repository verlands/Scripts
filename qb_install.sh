#!/bin/bash

################################################
###
###     安装 qbittorrent-nox 并设置守护进程
###
################################################

# 下载qbittorrent-nox二进制文件并设置权限

# 下载qbittorrent-nox二进制文件，版本为4.4.5
# 4.4.0及以后版本吃配置，上传慢，推荐4.3.8/9，更稳定，内存占用更小

# 询问用户选择并安装
while true; do
    echo "请选择要安装的 qBittorrent 版本："
    echo "1) qbittorrent 4.3.9 libtorrent 1.2.15"
    echo "2) qbittorrent 4.4.5 libtorrent 2.0.8"
    read -p "输入您的选择 (1 或 2): " VERSION_CHOICE

    case $VERSION_CHOICE in
        1)
            QB_VERSION=4.3.9
            LIBTORRENT_VERSION=1.2.15
            break
            ;;
        2)
            QB_VERSION=4.4.5
            LIBTORRENT_VERSION=2.0.8
            break
            ;;
        *)
            echo "输入错误，请重新输入。"
            ;;
    esac
done

RELEASE_URL="https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-${QB_VERSION}_v${LIBTORRENT_VERSION}/$(uname -m)-qbittorrent-nox"
echo "正在下载 qBittorrent ${QB_VERSION} ... 和 libtorrent ${LIBTORRENT_VERSION} ..."
wget -qO "/usr/local/bin/qbittorrent-nox" "$RELEASE_URL" 

if [ $? -eq 0 ]; then
    chmod +x /usr/local/bin/qbittorrent-nox
    echo "qBittorrent ${QB_VERSION} 安装成功。"
else
    echo "下载失败，请检查网络连接或下载链接是否正确。"
fi

# wget -qO /usr/local/bin/qbittorrent-nox "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.3.9_v1.2.15/$(uname -m)-qbittorrent-nox"

# 设置qbittorrent-nox二进制文件的权限为700
# chmod 700 /usr/local/bin/qbittorrent-nox

# 创建Systemd服务单元文件，即 qbittorrent 守护进程

# 定义服务单元文件路径
service_file="/etc/systemd/system/qb.service"

# 创建并编辑服务单元文件
cat << EOF > $service_file 这行不知道有没有问题
# sudo tee $service_file <<EOF
[Unit]
Description=qBittorrent Daemon Service
After=network.target

[Service]
# 下面命令加 "-d" 会使得守护进程没用，去掉以后，需要将Type改为 simple，这样就有用了，可能原因如下：
# GPT4：您的 qbittorrent-nox 服务在启动后立即退出，这可能是因为 -d 参数不再需要。在 qbittorrent-nox 较新的版本中，直接运行命令默认就是以守护进程方式运行，无需 -d 参数。
# 不是root用户可能能用forking 以及 -d，未实践
# Type=forking
Type=simple
User=root
# ExecStart=/usr/local/bin/qbittorrent-nox -d --webui-port=12380
ExecStart=/usr/local/bin/qbittorrent-nox --webui-port=12380
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 提示服务单元文件已创建
echo "qbittorrent 守护进程已创建：$service_file"

# 更新配置
systemctl daemon-reload

# 启用qbittorrent-nox服务
systemctl enable qb.service

# 启动qbittorrent-nox服务
systemctl start qb.service

# 关闭qbittorrent-nox服务
systemctl stop qb.service

# 提示用户输入用户名和密码
read -p "请输入 QB WebUI 登录用户名：" username
read -sp "请输入 QB WebUI 登录密码：" password
echo

# 新建qb下载目录
mkdir -p /root/Downloads/qbittorrent/

########## 是否安装 VueTorrent 第三方 qb webui 客户端
# 确认是否安装 vuetorrent
while true; do
    read -p "是否需要安装 vuetorrent? (默认为yes) [Y/n] " yn
    if [[ -z "$yn" || "$yn" = [Yy] || "$yn" = [Yy][Ee][Ss] ]]; then
        vuetorrent=true
        echo "您选择了安装 vuetorrent。"
        break
    elif [[ "$yn" = [Nn] || "$yn" = [Nn][Oo] ]]; then
        vuetorrent=false
        echo "您选择了不安装 vuetorrent。"
        break

    else
        echo "无效输入，请输入 Y 或 N。"
    fi
done

# 如果用户选择了安装 vuetorrent，则运行安装命令
if $vuetorrent; then
    echo "正在安装 vuetorrent..."
    git clone --single-branch --branch latest-release https://github.com/VueTorrent/VueTorrent.git
    # 您也可以在这里添加任何其他必要的安装步骤
    echo "vuetorrent 安装完成。"
fi


####### 生成 qb 配置文件，设置登录用户名和密码，ui界面语言设为中文
if [[ "${QB_VERSION}" =~ "4.2."|"4.3." ]]; then
    wget  https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qb_password_gen && chmod +x $HOME/qb_password_gen
    PBKDF2password=$($HOME/qb_password_gen $password)
    cat << EOF >/root/.config/qBittorrent/qBittorrent.conf
[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
Connection\PortRangeMin=45000
Downloads\SavePath=/root/Downloads/qbittorrent/
General\Locale=zh
Queueing\QueueingEnabled=false
WebUI\AlternativeUIEnabled=$vuetorrent
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=12380
WebUI\RootFolder=/root/VueTorrent
WebUI\Username=$username
EOF
elif [[ "${QB_VERSION}" =~ "4.4."|"4.5."|"4.6." ]]; then
    wget  https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qb_password_gen && chmod +x $HOME/qb_password_gen
    PBKDF2password=$($HOME/qb_password_gen $password)
    cat << EOF >/root/.config/qBittorrent/qBittorrent.conf
[BitTorrent]
Session\DefaultSavePath=/root/Downloads/qbittorrent/
Session\Port=45000
Session\QueueingSystemEnabled=false

[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
General\Locale=zh
WebUI\AlternativeUIEnabled=$vuetorrent
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=12380
WebUI\RootFolder=/root/VueTorrent
WebUI\Username=$username
EOF
rm qb_password_gen
fi

# # 修改 qbittorrent WebUI 界面语言为 中文
# QB_CONFIG_FILE="/root/.config/qBittorrent/qBittorrent.conf"
# # 检查是否存在[Preferences]部分
# if grep -q "\[Preferences\]" "$QB_CONFIG_FILE"; then
#     # [Preferences]部分存在
#     # 使用awk在[Preferences]下方添加设置项，如果设置项已存在则替换
#     awk -v config="General\\Locale=zh" '/^\[Preferences\]/ {print; found=1; next} found && !/^\[/{print config; config=""; found=0} 1' "$QB_CONFIG_FILE" > temp_config && mv temp_config "$QB_CONFIG_FILE"
# else
#     # [Preferences]部分不存在, 在文件末尾添加[Preferences]和设置项
#     echo -e "\n[Preferences]" >> "$QB_CONFIG_FILE"
#     echo "General\\Locale=zh" >> "$QB_CONFIG_FILE"
# fi



# ################################################
# ###
# ###     安装 autobrr 并设置守护进程
# ###
# ################################################

# # 下载autobrr
# wget $(curl -s https://api.github.com/repos/autobrr/autobrr/releases/latest | grep download | grep linux_x86_64 | cut -d\" -f4)

# # 解压 autobrr 和 autobrrctl 到 /usr/local/bin，如果不是root用户，可以解压到 ~/.bin 目录内
# sudo tar -C /usr/local/bin -xzf autobrr*.tar.gz

# # 创建配置目录
# mkdir -p ~/.config/autobrr

# # 配置文件
# CONFIG_FILE="/root/.config/autobrr/config.toml"
# curl -o $CONFIG_FILE -L https://raw.githubusercontent.com/autobrr/autobrr/develop/config.toml
# # 修改配置文件，使得可以远程连接
# sudo sed -i 's/host = "127.0.0.1"/host = "0.0.0.0"/' $CONFIG_FILE
# # 修改网页端口默认端口
# sudo sed -i 's/port = 7474/port = 12381/' $CONFIG_FILE

# # 创建 systemd 服务文件
# AUTOBRR_SERVICE=/etc/systemd/system/autobrr.service
# sudo tee $AUTOBRR_SERVICE <<EOF
# [Unit]
# Description=autobrr daemon
# After=network-online.target

# [Service]
# User=root
# Group=root
# Type=simple
# ExecStart=/usr/local/bin/autobrr --config=/root/.config/autobrr/
# Restart=on-failure
# RestartSec=5

# [Install]
# WantedBy=multi-user.target
# EOF

# # 提示服务单元文件已创建
# echo "Autobrr 守护进程已创建：$AUTOBRR_SERVICE"

# # 更新配置
# systemctl daemon-reload

# # 添加 qb 和 autobrr 命令别名
# echo "alias qb=\"service qb\"" >> ~/.zshrc
# echo "alias auto=\"service autobrr\"" >> ~/.zshrc
# # 使得别名生效
# source ~/.zshrc

# # 启用qbittorrent-nox服务
# systemctl enable qb.service
# systemctl enable autobrr

# # 启动qbittorrent-nox服务
# systemctl start qb.service
# systemctl start autobrr

# # 提示启用和启动服务的命令
# echo "qbittorrent-nox 和 autobrr 服务已启用和启动。"
# echo "qb enable: 设置开机启动"
# echo "qb disable: 关闭开机启动"
# echo "qb start: 开启服务"
# echo "qb stop: 关闭服务"
# echo "qb restart: 重启服务"
# echo "qb status: 查看服务状态"
# echo "autobrr同理，只需要将上面命令里面的 qb 改为 auto"

# # 获取本机IP地址
# ip_address=$(hostname -I | awk '{print $1}')

# # 提示打开qbittorrent的命令
# echo "要访问qbittorrent，请在浏览器中打开：http://$ip_address:12380"
# echo "要访问 autobrr，请在浏览器中打开：http://$ip_address:12381"



