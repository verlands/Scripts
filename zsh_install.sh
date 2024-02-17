#!/bin/bash

# 安装 zsh
sudo apt-get update
sudo apt-get install -y zsh git wget screen curl sshpass vim

# 安装 oh-my-zsh，并设置当前shell为zsh
yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 安装 zsh-autosuggestions 插件
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# 安装 zsh-syntax-highlighting 插件
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# 修改主题为 ys
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="ys"/' ~/.zshrc

# 启用插件
sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting z extract)/' ~/.zshrc

# 启用 autosuggest-accept 快捷键
echo 'bindkey "," autosuggest-accept' >> ~/.zshrc

# 修改终端默认 shell 为 zsh
chsh -s $(which zsh)

# 重新启动 zsh
exec zsh

# 在脚本最后添加删除自身的命令
# rm -- "$0" && exit
