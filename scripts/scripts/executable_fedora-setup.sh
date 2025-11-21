#!/bin/bash

set -e  # exit on error
cd ~

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

echo -e "\n==== System update ===="
sudo dnf update -y
sudo dnf upgrade -y

echo -e "\n==== Installing dev dependencies ===="
DEPS=(
  bat difftastic dnsutils fzf gcc git-delta gnupg httpie jq make
  restic rclone ripgrep tmux tree-sitter-cli wget wl-clipboard xclip zoxide yazi zsh
)
for pkg in "${DEPS[@]}"; do
  if ! command_exists "$pkg"; then
    echo "Installing $pkg..."
    sudo dnf install -y "$pkg"
  else
    echo "$pkg is already installed."
  fi
done

echo -e "\n==== Docker setup ===="
if ! command_exists docker; then
  echo "Installing Docker..."

  sudo dnf remove -y docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate docker-selinux \
    docker-engine-selinux docker-engine || true

  sudo dnf -y install dnf-plugins-core
  sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo groupadd -f docker
  sudo usermod -aG docker "$USER"
else
  echo "Docker is already installed."
fi

echo -e "\n==== Set ZSH as default shell ===="
if [ "$SHELL" != "$(which zsh)" ]; then
  sudo chsh -s "$(which zsh)"
else
  echo "ZSH is already the default shell."
fi

echo -e "\n==== Installing asdf ===="
if [ ! -d "$HOME/.asdf" ]; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
else
  echo "asdf is already installed."
fi

echo -e "\n==== Downloading Nerd Font (JetBrainsMono) ===="
FONT_DIR="$HOME/.fonts"
FONT_NAME="JetBrainsMono"
if [ ! -d "$FONT_DIR/$FONT_NAME" ]; then
  mkdir -p "$FONT_DIR"
  wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
  unzip -q JetBrainsMono.zip -d "$FONT_DIR/$FONT_NAME"
  fc-cache -fv
  rm JetBrainsMono.zip
else
  echo "Font $FONT_NAME already installed."
fi

echo -e "\n==== Installing AppImageLauncher support (if needed) ===="
if ! command_exists appimagelauncher; then
  echo "AppImageLauncher is not installed, you may need to install it manually via the official release or PPA."
else
  echo "AppImageLauncher is already installed."
fi

echo -e "\n==== Installing VsCode (if needed)====="
if ! command_exists code; then
  echo "Installing VsCode"
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

 dnf check-update
 sudo dnf install code
else
  echo "VsCode is already installed"
fi

echo -e "\n==== Checking for Flatpak ===="
if ! command_exists flatpak; then
  echo "Installing Flatpak..."
  sudo dnf install -y flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
else
  echo "Flatpak is already installed."
fi

echo -e "\n==== Updating and installing Flatpaks ===="
sudo dnf update -y
flatpak update -y

FLATPAK_APPS=(
  org.gnome.Extensions
  com.usebottles.bottles
  com.google.Chrome
  org.gnome.Boxes
  com.github.hluk.copyq
  dev.vencord.Vesktop
  com.github.tchx84.Flatseal
  org.flameshot.Flameshot
  com.logseq.Logseq
  com.getmailspring.Mailspring
  com.slack.Slack
  com.obsproject.Studio
  org.videolan.VLC
  org.wezfurlong.wezterm
  com.jetbrains.DataGrip
  com.jetbrains.IntelliJ-IDEA-Ultimate
  com.jetbrains.PyCharm-Professional
  com.jetbrains.Rider
  org.libreoffice.LibreOffice
  org.mozilla.firefox
  com.bitwarden.desktop
  com.rustdesk.RustDesk
)

for app in "${FLATPAK_APPS[@]}"; do
  if ! flatpak info "$app" &> /dev/null; then
    echo "Installing $app..."
    flatpak install -y flathub "$app"
  else
    echo "$app is already installed."
  fi
done

echo -e "\n==== All done! Please reboot the computer. ===="
echo "Install the necessary graphics drivers"
echo "Reload your .zshrc and consider installing:"
echo "  - Languages: python, node, jdk, dotnet, go"
echo "  - bpytop: pip install bpytop"
echo "  - Docker group fix: newgrp docker"
echo "  - Go apps: env CGO_ENABLED=0 go install -ldflags='-s -w' github.com/gokcehan/lf@latest"
