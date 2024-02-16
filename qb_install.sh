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
# sudo tee $service_file <<EOF
cat << EOF > $service_file
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

# # 启用qbittorrent-nox服务
# systemctl enable qb.service
# echo "Test: 1"

# # 启动qbittorrent-nox服务
# systemctl start qb.service
# echo "Test: 2"
# # 下面命令是为了刚启动qb就停止，会出问题，所以停下5秒
# sleep 5

# # 关闭qbittorrent-nox服务
# systemctl stop qb.service
# echo "Test: 3"

# 提示用户输入用户名和密码
read -p "请输入 QB WebUI 登录用户名：" username
read -sp "请输入 QB WebUI 登录密码：" password
echo

# 定义 qBittorrent 配置目录和文件的路径
QB_CONFIG_DIR="/root/.config/qBittorrent"
QB_CONFIG_FILE="$QB_CONFIG_DIR/qBittorrent.conf"

# 检查 qBittorrent 配置目录是否存在，不存在则创建
if [ ! -d "$QB_CONFIG_DIR" ]; then
    echo "配置目录 $QB_CONFIG_DIR 不存在，正在创建..."
    mkdir -p "$QB_CONFIG_DIR"
    if [ $? -ne 0 ]; then
        echo "创建配置目录 $QB_CONFIG_DIR 失败，脚本退出。"
        exit 1
    fi
else
    echo "配置目录 $QB_CONFIG_DIR 已存在。"
fi

# 检查 qBittorrent 配置文件是否存在，不存在则创建
if [ ! -f "$QB_CONFIG_FILE" ]; then
    echo "配置文件 $QB_CONFIG_FILE 不存在，正在创建..."
    touch "$QB_CONFIG_FILE"
    if [ $? -ne 0 ]; then
        echo "创建配置文件 $QB_CONFIG_FILE 失败，脚本退出。"
        exit 1
    fi
else
    echo "配置文件 $QB_CONFIG_FILE 已存在。"
fi

echo "qBittorrent 配置目录和文件检查完毕。"

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
CONFIG_FILE="/root/.config/autobrr/config.toml"
curl -o $CONFIG_FILE -L https://raw.githubusercontent.com/autobrr/autobrr/develop/config.toml
# 修改配置文件，使得可以远程连接
sudo sed -i 's/host = "127.0.0.1"/host = "0.0.0.0"/' $CONFIG_FILE
# 修改网页端口默认端口
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
echo "Autobrr 守护进程已创建：$AUTOBRR_SERVICE"





################################################
###
###     安装 autoremove-torrents 并设置定期运行
###
################################################

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
  username: $username
  password: $password
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

( crontab -l 2>/dev/null | grep -v "$art_path"; echo "*/1 * * * * $art_path --conf=${art_config_file} --log=${art_log_folder}" ) | crontab -

# 检查计划任务是否设置成功
if [ $? -ne 0 ]; then
    echo "添加或更新计划任务失败，退出。"
    exit 1
fi

echo "autoremove-torrents 设置成功，将每 1 分钟运行一次。"





# 更新配置
systemctl daemon-reload

# 添加 qb 和 autobrr 命令别名
echo "alias qb=\"service qb\"" >> ~/.zshrc
echo "alias auto=\"service autobrr\"" >> ~/.zshrc


# ##### 请注意该命令在bash脚本中运行会出错，虽然名别会生效，但不提倡这种做法 
# # 使得别名生效
# source ~/.zshrc
# ##### 应该选择创建一个临时Zsh脚本来执行source .zshrc命令
cat << 'EOF' > /tmp/source_zshrc.sh
#!/bin/zsh
echo "正在 source ~/.zshrc ..."
source ~/.zshrc
echo ".zshrc 载入完成。"
EOF
# 修改该脚本的权限，使其可执行
chmod +x /tmp/source_zshrc.sh
# 当Bash脚本完成后自动运行该Zsh脚本
echo "Zsh 脚本将被执行，以让别名改动立即生效"
zsh /tmp/source_zshrc.sh
# 删除临时Zsh脚本
rm /tmp/source_zshrc.sh




# 启用qbittorrent-nox服务
systemctl enable qb.service
systemctl enable autobrr

# 启动qbittorrent-nox服务
systemctl start qb.service
systemctl start autobrr

# 提示启用和启动服务的命令
echo "qbittorrent-nox 和 autobrr 服务已启用和启动。"
echo "qb enable: 设置开机启动"
echo "qb disable: 关闭开机启动"
echo "qb start: 开启服务"
echo "qb stop: 关闭服务"
echo "qb restart: 重启服务"
echo "qb status: 查看服务状态"
echo "autobrr同理，只需要将上面命令里面的 qb 改为 auto"

# 获取本机IP地址
ip_address=$(hostname -I | awk '{print $1}')

# 提示打开qbittorrent的命令
echo "要访问qbittorrent，请在浏览器中打开：http://$ip_address:12380"
echo "要访问 autobrr，请在浏览器中打开：http://$ip_address:12381"



