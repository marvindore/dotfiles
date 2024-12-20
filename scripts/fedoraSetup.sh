#!/bin/bash

cd ~
sudo dnf update #qq will make it quiet no imput on the screen
sudo dnf upgrade -y

# dev dependencies
sudo dnf install -yy bat difftastic dnsutils \
    fzf gcc git-delta gnupg httpie jq make \
    rclone ripgrep tmux tree-sitter-cli wget wl-clipboard xclip zoxide zsh

# Droid cam (https://www.dev47apps.com/droidcam/linux/)
# sudo apt install -y v4l2loopback-dkms v4l2loopback-utils libappindicator3-1 linux-headers-$(uname -r)

# install docker
# first remove any old versions
sudo dnf remove docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate docker-selinux \
    docker-engine-selinux docker-engine

sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# run docker without sudo
sudo groupadd docker
sudo usermod -aG docker $USER

echo "Set ZSH default============"
sudo chsh -s $(which zsh)

echo "========= Installing asdf =========="
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
#dependencies https://github.com/pyenv/pyenv/wiki#suggested-build-environment

# gopls install error GOPROXY list is not the empty string but contains no entries
# do the following - unset GOROOT
echo "====== Downloading fonts ======"
echo "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.fonts
fc-cache -fv

# Install AppimageLauncher and common appimage dependencies
sudo dnf install -y software-properties-common
# sudo add-apt-repository ppa:appimagelauncher-team/stable
# sudo apt update
# sudo apt install -y appimagelauncher

# sudo apt install -yy fuse3 libfuse2
# mkdir ~/.executables
# cd ~/.executables
# curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
# chmod u+x nvim.appimage
cd ~

# echo "Lazygit"
# LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
# curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
# tar xf lazygit.tar.gz lazygit
# sudo install lazygit /usr/local/bin

# echo "Mongodb"
# wget https://downloads.mongodb.com/compass/mongodb-compass_1.42.5_amd64.deb
# sudo dpkg -i mongodb-compass_1.42.5_amd64.deb

# wget -qO- https://www.mongodb.org/static/pgp/server-7.0.asc | sudo tee /etc/apt/trusted.gpg.d/server-7.0.asc
# echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
# sudo apt install -y mongodb-mongosh
#
# Install Flatpak
# {
#   flatpak --version
# } || {
#   echo "Installing flatpak software..."
#   sudo dnf install -yy flatpak
#   flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# }

echo "========= Installing Flatpaks ========="
# sudo apt --fix-broken install
sudo dnf update
flatpak update

flatpak install -yy flathub \
    com.usebottles.bottles \
    com.google.Chrome \
    com.github.hluk.copyq \
    com.discordapp.Discord \
    com.github.tchx84.Flatseal \
    org.flameshot.Flameshot \
    com.logseq.Logseq \
    com.getmailspring.Mailspring \
    com.slack.Slack \
    com.obsproject.Studio \
    org.videolan.VLC \
    org.wezfurlong.wezterm \
    com.jetbrains.DataGrip \
    com.jetbrains.IntelliJ-IDEA-Ultimate \
    com.jetbrains.PyCharm-Professional \
    com.jetbrains.Rider \
    com.jetbrains.WebStorm

echo "All done! Please reboot the computer"
echo "Reloud zshrc and set a few things"
echo "python, node, jdk, dotnet, go
pip install bpytop
sudo usermod -aG docker \${USER}
newgrp docker
install these go apps: go
env CGO_ENABLED=0 go install -ldflags="-s -w" github.com/gokcehan/lf@latest"
