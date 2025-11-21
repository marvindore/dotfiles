#!/bin/bash

: '
===========================
Post-Installation Steps
===========================

1. Install NVIDIA Drivers:
   - Visit the official Arch Wiki page for NVIDIA:
     https://wiki.archlinux.org/title/NVIDIA

2. Enable DRM for NVIDIA:
   - Open the GRUB configuration file:
     sudo nano /etc/default/grub

   - Modify the GRUB_CMDLINE_LINUX_DEFAULT line:
     From:
       GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
     To:
       GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia_drm.modeset=1"

   - Regenerate the GRUB config:
     sudo grub-mkconfig -o /boot/grub/grub.cfg
'

set -euo pipefail

# ------------------------------------------------------------------------------
# Define packages to install via pacman
# ------------------------------------------------------------------------------

packages=(
  "alacritty"
  "bat"
  "base-devel"
  "difftastic"
  "docker"
  "exa"
  "fd"
  "firefox"
  "ffmpeg"
  "flatpak"
  "fzf"
  "git"
  "git-delta"
  "ghostscript" # for imagemagick pdf conversions
  "hyprland"
  "hyprlock"
  "hyprpaper"
  "imagemagick" # for yazi
  "jc"
  "jq"
  "mise"
  "openssh"
  "poppler" # for yazi
  "reflector"
  "resvg" # for yazi
  "ripgrep"
  "starship"
  "tree-sitter"
  "ttf-font-awesome"
  "ttf-nerd-fonts-symbols-mono"
  "waybar"
  "wofi"
  "yazi"
  "zellij"
  "zoxide"
  "zsh"
  "7zip"
)

# ------------------------------------------------------------------------------
# Symlink helper
# ------------------------------------------------------------------------------

link_file_with_prompt() {
  local source="$1"
  local target="$2"
  local target_dir

  target_dir="$(dirname "$target")"

  if [[ ! -d "$target_dir" ]]; then
    mkdir -p "$target_dir"
  fi

  if [[ -L "$target" ]]; then
    local existing_link
    existing_link="$(readlink "$target")"
    if [[ "$existing_link" == "$source" ]]; then
      echo "⏭️ Skipped: Symlink already exists → $target"
      return
    else
      echo "⚠️ Symlink '$target' points to '$existing_link'."
      read -rp "Replace with new symlink? (y/N): " response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        rm "$target"
        ln -s "$source" "$target"
        echo "✅ Linked: $target → $source"
      else
        echo "⏭️ Skipped: $target"
      fi
      return
    fi
  elif [[ -e "$target" ]]; then
    echo "⚠️ File '$target' exists and is not a symlink."
    read -rp "Delete and replace with symlink? (y/N): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      rm -rf "$target"
      ln -s "$source" "$target"
      echo "✅ Linked: $target → $source"
    else
      echo "⏭️ Skipped: $target"
    fi
    return
  else
    ln -s "$source" "$target"
    echo "✅ Linked: $target → $source"
  fi
}

# ------------------------------------------------------------------------------
# Create dotfile symlinks
# ------------------------------------------------------------------------------

stow_dotfiles_manually() {
  local context_is_work=false
  read -rp "Setting up dotfiles for work? (y/N): " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    context_is_work=true
  fi

  local context_dir="$HOME/dotfiles"

  if [[ ! -d "$context_dir" ]]; then
    echo "❌ Dotfiles directory '$context_dir' does not exist."
    exit 1
  fi

  echo "🔗 Linking dotfiles from '$context_dir' into $HOME..."

  find "$context_dir" -path "$context_dir/.git" -prune -o -type f -print | while read -r file; do
    relative_path="${file#$context_dir/}"
    target="$HOME/$relative_path"
    link_file_with_prompt "$file" "$target"
  done

  if $context_is_work; then
    link_file_with_prompt "$HOME/dotfiles/.ssh/config-work-windows" "$HOME/.ssh/config"
  else
    link_file_with_prompt "$HOME/dotfiles/.ssh/config-marvin-windows" "$HOME/.ssh/config"
  fi

  ln -s "$HOME/dotfiles/scripts/open-url" "$HOME/bin/open-url"
}

# ------------------------------------------------------------------------------
# Remove dotfile symlinks
# ------------------------------------------------------------------------------

unstow_dotfiles_manually() {
  local context_is_work=false
  read -rp "Remove dotfiles for work? (y/N): " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    context_is_work=true
  fi

  local context_dir="$HOME/dotfiles"

  if [[ ! -d "$context_dir" ]]; then
    echo "❌ Dotfiles directory '$context_dir' does not exist."
    exit 1
  fi

  echo "🗑️ Removing symlinks from '$context_dir' in $HOME..."

  find "$context_dir" -path "$context_dir/.git" -prune -o -type f -print | while read -r file; do
    relative_path="${file#$context_dir/}"
    target="$HOME/$relative_path"
    if [[ -L "$target" ]]; then
      rm "$target"
      echo "❌ Removed symlink: $target"
    else
      echo "⏭️ Skipped (not a symlink): $target"
    fi
  done

  local ssh_config="$HOME/.ssh/config"
  if [[ -L "$ssh_config" ]]; then
    rm "$ssh_config"
    echo "❌ Removed symlink: $ssh_config"
  fi

  sudo rm /usr/local/bin/open-url
}

# ------------------------------------------------------------------------------
# Setup Neovim AppImage
# ------------------------------------------------------------------------------

setup_neovim() {
  local nvim_path="$HOME/bin/nvim"
  local download_url="https://github.com/neovim/neovim/releases/download/v0.11.3/nvim-linux-x86_64.appimage"

  mkdir -p "$HOME/bin"

  if [[ -f "$nvim_path" ]]; then
    echo "📝 Neovim already exists at $nvim_path"
    read -rp "Redownload Neovim? (y/N): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      echo "🔄 Redownloading Neovim..."
      rm "$nvim_path"
      curl -L -o "$nvim_path" "$download_url"
      chmod u+x "$nvim_path"
      echo "✅ Neovim updated at $nvim_path"
    else
      echo "⏭️ Skipped Neovim download."
    fi
  else
    echo "⬇️ Downloading Neovim..."
    curl -L -o "$nvim_path" "$download_url"
    chmod u+x "$nvim_path"
    echo "✅ Neovim installed at $nvim_path"
  fi
}

# ------------------------------------------------------------------------------
# Setup AUR helper (paru)
# ------------------------------------------------------------------------------

setup_aur_helper() {
  if ! command -v paru &>/dev/null; then
    echo "🔧 Installing paru (AUR helper)..."
    sudo pacman -S --noconfirm --needed base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    pushd /tmp/paru
    makepkg -si --noconfirm
    popd
    rm -rf /tmp/paru
    echo "✅ paru installed"
  else
    echo "✅ paru is already installed"
  fi
}

# ------------------------------------------------------------------------------
# Setup Hyprland config and Wayland tweaks
# ------------------------------------------------------------------------------

setup_hyprland_config() {
  echo "🔤 Installing JetBrains Mono Nerd Font..."
  sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd
  
  echo "🛠️ Setting JetBrains Mono Nerd Font as default monospace font..."
  
  FONTCONF_PATH="$HOME/.config/fontconfig/fonts.conf"
  
  if [[ -f "$FONTCONF_PATH" ]]; then
    echo "⚠️ Font config already exists at $FONTCONF_PATH."
    read -rp "Overwrite with JetBrains Mono config? (y/N): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "⏭️ Skipped font config update."
    else
      write_font_config=true
    fi
  else
    write_font_config=true
  fi
  
  if [[ "${write_font_config:-false}" == true ]]; then
    mkdir -p "$(dirname "$FONTCONF_PATH")"
    printf '%s\n' \
      '<?xml version="1.0"?>' \
      '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' \
      '<fontconfig>' \
      '  <match target="pattern">' \
      '    <test name="family" qual="any">' \
      '      <string>monospace</string>' \
      '    </test>' \
      '    <edit name="family" mode="assign" binding="strong">' \
      '      <string>JetBrainsMono Nerd Font</string>' \
      '    </edit>' \
      '  </match>' \
      '</fontconfig>' > "$FONTCONF_PATH"
  
    echo "🔄 Refreshing font cache..."
    fc-cache -fv
    echo "✅ JetBrains Mono Nerd Font set as default monospace font."
  fi
}

# ------------------------------------------------------------------------------
# Install packages
# ------------------------------------------------------------------------------

install_packages() {
  echo "📦 Installing packages with pacman..."
  for pkg in "${packages[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
      echo "➡️ Installing $pkg..."
      sudo pacman -S --noconfirm "$pkg"
    else
      echo "✅ $pkg is already installed, skipping..."
    fi
  done

  setup_aur_helper
  setup_neovim
  setup_hyprland_config
}

# ------------------------------------------------------------------------------
# Print numbered list
# ------------------------------------------------------------------------------

print_numbered_list() {
  echo "0. Create dotfile symlinks"
  echo "1. Remove dotfile symlinks"
  echo "2. Install packages (includes Neovim, AUR, Hyprland config, Wayland tweaks)"
}

# ------------------------------------------------------------------------------
# Parse input like 0,2 or 0-2
# ------------------------------------------------------------------------------

selected=()

parse_selection() {
  local input="$1"
  if [[ "$input" == "all" ]]; then
    selected=(0 1 2)
    return
  fi

  IFS=',' read -r -a parts <<< "$input"
  for part in "${parts[@]}"; do
    if [[ "$part" =~ ^[0-9]+$ ]]; then
      selected+=("$part")
    elif [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      start=${BASH_REMATCH[1]}
      end=${BASH_REMATCH[2]}
      for ((i=start; i<=end; i++)); do selected+=("$i"); done
    else
      echo "Invalid input: $part"
      exit 1
    fi
  done
}

# ------------------------------------------------------------------------------
# Execute selected actions
# ------------------------------------------------------------------------------

execute_selected() {
  for index in "${selected[@]}"; do
    case "$index" in
      0) stow_dotfiles_manually ;;
      1) unstow_dotfiles_manually ;;
      2) install_packages ;;
      *) echo "Invalid selection: $index" ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
  print_numbered_list
  echo -e "\nEnter numbers to run (e.g. 0,2 or 0-2 or 'all'):"
  read -r selection
  parse_selection "$selection"
  execute_selected
  echo -e "\n✅ Setup complete!"

  # ------------------------------------------------------------------------------
  # Set default shell to Zsh if not already set
  # ------------------------------------------------------------------------------
  
  if [[ "$SHELL" != *"zsh" ]]; then
    if command -v zsh >/dev/null 2>&1; then
      echo "🔄 Changing default shell to Zsh..."
      chsh -s "$(command -v zsh)"
    else
      echo "❌ Zsh is not installed. Skipping shell change."
    fi
  else
    echo "✅ Default shell is already Zsh."
  fi
}

main

# install wezterm
# curl -LO https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-Ubuntu20.04.AppImage
