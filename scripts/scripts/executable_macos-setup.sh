#!/bin/bash

set -euo pipefail

# ------------------------------------------------------------------------------
# Define packages and casks
# ------------------------------------------------------------------------------

packages=(
  "atuin" "bruno" "difftastic" "tree-sitter" "bat" "bitwarden"
  "exa" "fzf" "gh" "git" "git-delta"
  "gnupg" "httpie" "jc" "jq" "k9s" "logseq" "mise" "nushell"
  "sst/tap/opencode" "ripgrep" "starship" "tealdeer" 
  "wezterm@nightly" "zellij" "zoxide"
)

casks=(
  "datagrip" "docker" "hammerspoon"
  "jordanbaird-ice", "ilspy" "intellij-idea" "font-jetbrains-mono-nerd-font" "google-chrome"
  "meld" "rider" "scoot" "slack"
)

# ------------------------------------------------------------------------------
# Configure personal macOS settings
# ------------------------------------------------------------------------------

configure_personal_settings() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Configuring macOS personal settings..."
    defaults write com.apple.dock persistent-apps -array
    killall Dock || true
    defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
    defaults write com.apple.dock appswitcher-all-displays -bool true
    killall Dock || true
  else
    echo "Skipping macOS settings — not running on macOS."
  fi
}

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
    # Target is a symlink
    local existing_link
    existing_link="$(readlink "$target")"
    if [[ "$existing_link" == "$source" ]]; then
      echo "⏭️ Skipped: Symlink already exists and points to correct source → $target"
      return
    else
      echo "⚠️ Symlink '$target' points to '$existing_link' instead of '$source'."
      read -rp "Replace with new symlink? (y/N): " response
      if [[ "$response" =~ ^(Y|y|Yes|yes)$ ]]; then
        rm "$target"
        ln -s "$source" "$target"
        echo "✅ Linked: $target → $source"
      else
        echo "⏭️ Skipped: $target"
      fi
      return
    fi
  elif [[ -e "$target" ]]; then
    # Target is a regular file or directory
    echo "⚠️ File '$target' exists and is not a symlink."
    read -rp "Delete and replace with symlink? (y/N): " response
    if [[ "$response" =~ ^(Y|y|Yes|yes)$ ]]; then
      rm -rf "$target"
      ln -s "$source" "$target"
      echo "✅ Linked: $target → $source"
    else
      echo "⏭️ Skipped: $target"
    fi
    return
  else
    # Target does not exist
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

  if [[ "$response" =~ ^(Y|y|Yes|yes)$ ]]; then
    context_is_work=true
  fi

  local context_dir="$HOME/dotfiles"

  if [[ ! -d "$context_dir" ]]; then
    echo "❌ Dotfiles directory '$context_dir' does not exist."
    exit 1
  fi

  echo "🔗 Linking dotfiles from '$context_dir' into $HOME... (supports filenames without spaces)"

  for file in $(find "$context_dir" -path "$context_dir/.git" -prune -o -type f -print); do
    relative_path="${file#$context_dir/}"
    target="$HOME/$relative_path"
    link_file_with_prompt "$file" "$target"
  done

  if $context_is_work; then
    link_file_with_prompt "$HOME/dotfiles/.ssh/config-work" "$HOME/.ssh/config"
  else
    link_file_with_prompt "$HOME/dotfiles/.ssh/config-marvin" "$HOME/.ssh/config"
  fi

  sudo ln -s "$HOME/dotfiles/scripts/open-url" /usr/local/bin/open-url
}

# ------------------------------------------------------------------------------
# Delete dotfile symlinks
# ------------------------------------------------------------------------------

unstow_dotfiles_manually() {
  local context_is_work=false
  read -rp "Remove dotfiles for work? (y/N): " response
  if [[ "$response" =~ ^(Y|y|Yes|yes)$ ]]; then
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
# Print numbered list
# ------------------------------------------------------------------------------

print_numbered_list() {
  echo "0. Create dotfile symlinks"
  echo "1. Remove dotfile symlinks"
  echo "2. Configure macOS personal settings"

  echo "Available packages:"
  local i=3
  for pkg in "${packages[@]}"; do
    printf "%2d. %s\n" "$i" "$pkg"
    i=$((i + 1))
  done

  echo -e "\nAvailable casks:"
  for cask in "${casks[@]}"; do
    printf "%2d. %s\n" "$i" "$cask"
    i=$((i + 1))
  done
}

# ------------------------------------------------------------------------------
# Parse input like 1,3,5-7 into array of indices
# ------------------------------------------------------------------------------

selected=()

parse_selection() {
  local input="$1"
  local total=$(( ${#packages[@]} + ${#casks[@]} + 3 ))

  if [ "$input" = "all" ]; then
    for ((i=2; i<=total; i++)); do selected+=("$i"); done
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
# Install selected packages and casks
# ------------------------------------------------------------------------------

install_selected_items() {
  local total=${#packages[@]}

  for index in "${selected[@]}"; do
    if (( index == 0 )); then
      stow_dotfiles_manually
    elif (( index == 1 )); then
      unstow_dotfiles_manually
    elif (( index == 2 )); then
      configure_personal_settings
    elif (( index >= 3 && index < 3 + total )); then
      pkg="${packages[index - 3]}"
      if ! brew list "$pkg" &>/dev/null; then
        echo "Installing $pkg..."
        brew install "$pkg"
      else
        echo "$pkg is already installed, skipping..."
      fi
    elif (( index >= 3 + total && index <= 2 + total + ${#casks[@]} )); then
      cask="${casks[index - 3 - total]}"
      if ! brew list --cask "$cask" &>/dev/null; then
        echo "Installing $cask..."
        brew install --cask "$cask"
      else
        echo "$cask is already installed, skipping..."
      fi
    else
      echo "Invalid selection: $index"
    fi
  done
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
  print_numbered_list
  echo -e "\nEnter numbers to install (e.g. 0,2,4-6 or 'all'):"
  read -r selection

  parse_selection "$selection"
  install_selected_items

  echo -e "\n✅ Setup complete!"
}

main
