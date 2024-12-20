#!/bin/bash

echo "Checking Logs and failed services"
systemctl --failed
systemctl list-unit-files
systemctl journalctl -p 3 -xb  // overal journal of errors

read -n 1 -s -r -p "Press enter to continue"

#NOTE: If you can't boot: CTL + ATL + F2 // boots to terminal

#Update the pacman mirrors:, because some develop latency or fall off
sudo pacman -S --noconfirm pacman-contrib
cd /
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

curl -s "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

#Clear Cache from package manage THEN refresh database
sudo pacman -Syyu

echo "Remember do not download too many packages from AUR as users sometimes stop maintaining their creation..."
echo "Done"
