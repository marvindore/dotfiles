# Dotfiles

Personal dotfiles managed with chezmoi and Nix.

## Primary platform
macOS

## Docs
- docs/macos.md — full macOS bootstrap and usage
- docs/system.md — secrets, git, and chezmoi behavior
- docs/affine.md — AFFiNE self-hosted setup with OneDrive backups
- docs/linux.md — partial support notes
- docs/windows.md — limited support

## Bootstrap
sh -c "$(curl -fsLS get.chezmoi.io)" -- init marvindore --apply
