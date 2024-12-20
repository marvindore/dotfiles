#!/bin/bash

# (source destination)
zsh=("${HOME}/.dotfiles/zsh" "${HOME}/.config/zsh")
zprofile=("${HOME}/.dotfiles/.zprofile" "${HOME}/.zprofile")
nvim=("${HOME}/.dotfiles/nvim" "${HOME}/.config/nvim")
alias=("${HOME}/.dotfiles/.alias" "${HOME}/.alias")
wezterm=("${HOME}/.dotfiles/wezterm/.wezterm.lua" "${HOME}/.wezterm.lua")
ideavim=("${HOME}/.dotfiles/.ideavimrc" "${HOME}/.ideavimrc")
asdf=("${HOME}/.dotfiles/.tool-versions" "${HOME}/.tool-versions")
tmux=("${HOME}/.dotfiles/.tmux.conf" "${HOME}/.tmux.conf")
docker_daemon=("${HOME}/.dotfiles/.daemon.json" "${HOME}/.daemon.json")

# Function to delete a file or directory if it exists
delete_if_exists() {
    local path=$1
    if [ -e "$path" ]; then
        echo "Deleting $path"
        rm -rf "$path"
    fi
}

# Function to create symbolic links
create_symlink() {
    local src=$1
    local dest=$2

    # Check if the destination exists and delete it if necessary
    delete_if_exists "$dest"

    # Create the symbolic link
    ln -s "$src" "$dest"
    echo "Created symlink: $dest -> $src"
}

# Simplified function to process each array of size 2
process_array() {
    arr=("$@")

    local src="${arr[0]}"
    local dest="${arr[1]}"

    create_symlink "$src" "$dest"
}

# Process each array
process_array "${zsh[@]}"
process_array "${alias[@]}"
process_array "${zprofile[@]}"
process_array "${nvim[@]}"
process_array "${wezterm[@]}"
process_array "${ideavim[@]}"
process_array "${asdf[@]}"
process_array "${tmux[@]}"
process_array "${docker_daemon[@]}"
