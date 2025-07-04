#!/bin/bash

# Script to configure macOS environment with Homebrew packages and clean the Dock.
# This script removes all items from the Dock and installs specified Homebrew packages.
# https://www.shell-tips.com/mac/defaults/#gsc.tab=0

set -e # Exit on any errors.
set -u # Treat unset variables as an error.

# ------------------------------------------------------------------------------
# Function to remove all items from the Dock.
# ------------------------------------------------------------------------------

configure_personal_settings() {
  echo "Removing all items from the Dock..."
  defaults write com.apple.dock persistent-apps -array
  killall Dock
  echo "Disabling click wallpaper to shoow desktop..."
  defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
  defaults write com.apple.dock appswitcher-all-displays -bool true # Show app switcher on all displays
  Killall Dock
}

# ------------------------------------------------------------------------------
# Function to install Homebrew packages.
# ------------------------------------------------------------------------------

install_brew_packages() {
  echo "Installing Homebrew packages..."
  
  # List of packages to install
  local packages=(
    "asdf"
    "difftastic"
    "tree-sitter"
    "bat"
    "fzf"
    "gh"
    "git"
    "git-delta"
    "gnupg"
    "httpie"
    "logseq"
    "ripgrep"
    "stow"
    "tealdeer"
    "zoxide"
  )

  local casks=(
    "azure-data-studio"
    "datagrip"
    "docker"
    "hammerspoon"
    "intellij-idea"
    "font-jetbrains-mono"
    "google-chrome"
    "raycast"
    "rider"
    "scoot"
    "slack"
    "wezterm@nightly"
  )
  
  # Iterate through each package and install it if not already installed.
  for pkg in "${packages[@]}"; do
    if ! command -v "$pkg" &>/dev/null && ! brew list "$pkg" &>/dev/null; then
      echo "Installing $pkg..."
      brew install "$pkg"
    else
      echo "$pkg is already installed, skipping..."
    fi
  done

  # Iterate through casks and install it if not already installed.
  for csk in "${casks[@]}"; do
    if ! command -v "$csk" &>/dev/null && ! brew list "$csk" &>/dev/null; then
      echo "Installing $csk..."
      brew install --cask "$csk"
    else
      echo "$csk is already installed, skipping..."
    fi
  done
}

# ------------------------------------------------------------------------------
# Function to install Neovim nightly (special handling based on your input).
# ------------------------------------------------------------------------------

install_neovim_nightly() {
  echo "Installing Neovim nightly..."

  # Install Neovim nightly from a specific overlay (or package source)
  # You may need to adjust this to your exact package source if you use Nix or a custom tap.
  brew install neovim --HEAD
}

# ------------------------------------------------------------------------------
# Main configuration function.
# ------------------------------------------------------------------------------

main() {
  # Step 1: Remove all items from the Dock.
  configure_personal_settings
  
  # Step 2: Install necessary packages using Homebrew.
  install_brew_packages
  
  # Step 3: Install Neovim nightly (if needed).
  install_neovim_nightly
  
  echo "macOS configuration is complete!"
}

# ------------------------------------------------------------------------------
# Run the main function.
# ------------------------------------------------------------------------------

main

