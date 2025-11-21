# Arch
Install docker 
- sudo pacman -S docker
- sudo systemctl start docker.service
- sudo systemctl enable docker.service
- sudo usermod -aG docker $USER
- newgrp docker

Switch between proprietary and open drivers:
Keep `nvidia-utils` installed as it's used by both
- Switch to proprietary
`sudo pacman -Rns nvidia-open`
`sudo pacman -S nvidia nvidia-settings` nvidia-settings is just a gui to tweak the driver settings

- Switch back to open
`sudo pacman -Rns nvidia`
`sudo pacman -S nvidia-open`

After each switch reboot system
If you run into version mismatches run
`sudo mkinitcpio -P`

# Hyprland
automatically start on login: https://wiki.archlinux.org/title/Greetd#Enabling_autologin

# Mirrors
Backup old mirrors
`sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.old`

Configure reflector
    nvim /etc/xdg/reflector/reflector.conf

--save /etc/pacman.d/mirrorlist
--country US
--protocol https
--sort rate
--latest 10

Set reflector to run on reboot
    sudo systemctl enable reflector.service

Check if the new mirrorlist was generated
    bat /etc/pacman.d/mirrorlist

sudo pacman -Syyu
