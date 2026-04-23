#!/bin/bash

set -euo pipefail

# ------------------------------------------------------------------------------
# Define packages and casks
# ------------------------------------------------------------------------------

packages=(
  "act" "atuin" "bat" "bruno" "difftastic" "dua-cli" "tree-sitter" "bitwarden"
  "eza" "fzf" "gh" "git" "git-delta"
  "gnupg" "imagemagick" "iproute2mac" "jc" "jq" "k9s" "miller" "mise" 
  "pngpaste" "serie" "sesh" "opencode" "ripgrep" "starship" "tmux"
  "zoxide"
)

casks=(
  "datagrip" "docker" "hammerspoon"
  "jordanbaird-ice" "ilspy" "intellij-idea" "font-jetbrains-mono-nerd-font" 
  "ghostty" "google-chrome" "linearmouse" "meld" "rider" "scoot" "slack"
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
# Print numbered list
# ------------------------------------------------------------------------------

print_numbered_list() {
  echo "0. Configure macOS personal settings"

  echo -e "\nAvailable packages:"
  local i=1
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
# Parse input like 0,3,5-7 into array of indices
# ------------------------------------------------------------------------------

selected=()

parse_selection() {
  local input="$1"
  local total=$(( ${#packages[@]} + ${#casks[@]} ))

  if [ "$input" = "all" ]; then
    for ((i=0; i<=total; i++)); do selected+=("$i"); done
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
      configure_personal_settings
    elif (( index >= 1 && index <= total )); then
      pkg="${packages[index - 1]}"
      if ! brew list "$pkg" &>/dev/null; then
        echo "Installing $pkg..."
        brew install "$pkg" || echo "⚠️  Failed to install $pkg, continuing..."
      else
        echo "⏭️  $pkg is already installed, skipping..."
      fi
    elif (( index > total && index <= total + ${#casks[@]} )); then
      cask="${casks[index - 1 - total]}"
      if ! brew list --cask "$cask" &>/dev/null; then
        echo "Installing $cask..."
        brew install --cask "$cask" || echo "⚠️  Failed to install $cask, continuing..."
      else
        echo "⏭️  $cask is already installed, skipping..."
      fi
    else
      echo "⚠️  Invalid selection: $index"
    fi
  done
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
  print_numbered_list
  echo -e "\nEnter numbers to install/configure (e.g. 0,2,4-6 or 'all'):"
  read -r selection

  parse_selection "$selection"
  install_selected_items

  echo -e "\n✅ Setup complete!"
}

main
