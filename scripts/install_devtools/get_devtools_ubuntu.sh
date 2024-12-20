#!/bin/bash

apt-get update && apt-get install -y git software-properties-common build-essential
add-apt-repository -y ppa:neovim-ppa/unstable
apt-get install -y neovim
rm ~/.bashrc

# install plugin manager
git clone https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim

git clone --recursive https://github.com/marvinamari/.dotfiles.git # to manually download submodules use git submodule update --init --recursive
git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it

#chmod u+x "~/.bash_it/install.sh"
. "~/.bash_it/install.sh -s"
mkdir -p ~/.config
ln -s /.dotfiles/install_devtools/.bashrc ~/
ln -s /.dotfiles/nvim ~/.config/
ln -s /.dotfiles/.alias ~/

#~/.dotfiles/nvim/lua/lsp/install_lang_servers.sh

#. "~/.bashrc"
