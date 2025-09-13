#!/usr/bin/env bash
# --needed deps are: base-devel git
# git clone package
# inspect it's PKGBUILD
# makepkg -si
# pacman -Qm

AUR_DIR="$HOME/aur"

if [ ! -d "$AUR_DIR" ]; then
    echo "NO $AUR_DIR directory found. Exiting."
    exit 1
fi

for pkg in "$AUR_DIR"/*; do
    if [ -d "$pkg/.git" ]; then
        echo "=== Updating $(basename "$pkg") ==="
        cd "$pkg" || continue

        # Fetch new PKGBUILD
        git pull --quiet

        if [ -f PKGBUILD ]; then
            makepkg -si --noconfirm
        else
            echo "No PKGBUILD found in $pkg"
        fi
    fi
done
