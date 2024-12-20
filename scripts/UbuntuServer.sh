#!/bin/bash

cd ~
apt update -qq #qq will make it quiet no imput on the screen
apt upgrade -y

apt install -yy magic-wormhole ripgrep tmux git

# install docker
apt install -yy ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -yy docker-ce docker-ce-cli containerd.io docker-compose-plugin
# run docker without sudo
groupadd docker
usermod -aG docker $USER

echo "========= Installing asdf =========="
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2

# AppImage
apt install -yy fuse3 libfuse2
mkdir ~/Applications
cd ~/Applications
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
cd ~

