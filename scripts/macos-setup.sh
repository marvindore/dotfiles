#!/bin/bash

# Script to configure macOS environment with Homebrew packages and clean the Dock.
# This script removes all items from the Dock and installs specified Homebrew packages.

set -e # Exit on any errors.
set -u # Treat unset variables as an error.

# ------------------------------------------------------------------------------
# Function to remove all items from the Dock.
# ------------------------------------------------------------------------------

remove_from_dock() {
  echo "Removing all items from the Dock..."
  defaults write com.apple.dock persistent-apps -array
  killall Dock
}

# ------------------------------------------------------------------------------
# Function to install Homebrew packages.
# ------------------------------------------------------------------------------

install_brew_packages() {
  echo "Installing Homebrew packages..."
  
  # List of packages to install
  local packages=(
    "asdf"
    "tree-sitter"
    "bat"
    "fzf"
    "git"
    "gnupg"
    "logseq"
    "mkalias"
    "ripgrep"
    "stow"
    "tealdeer"
    "zoxide"
  )

  local casks=(
    "hammerspoon"
    "google-chrome"
    "raycast"
    "wezterm@nightly"
  )
  
  # Iterate through each package and install it if not already installed.
  for pkg in "${packages[@]}"; do
    if ! brew list "$pkg" &>/dev/null; then
      echo "Installing $pkg..."
      brew install "$pkg"
    else
      echo "$pkg is already installed, skipping..."
    fi
  done

  # Iterate through casks and install it if not already installed.
  for csk in "${casks[@]}"; do
    if ! brew list "$csk" &>/dev/null; then
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
  remove_from_dock
  
  # Step 2: Install necessary packages using Homebrew.
  install_brew_packages
  
  # Step 3: Install Neovim nightly (if needed).
  install_neovim_nightly
  
  # Step 4: Install asdf-vm (if needed).
  install_asdf_vm
  
  echo "macOS configuration is complete!"
}

# ------------------------------------------------------------------------------
# Run the main function.
# ------------------------------------------------------------------------------

main

