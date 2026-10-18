# Dotfiles

Personal dotfiles managed with chezmoi and Homebrew.

## Primary platform

macOS

## Docs

- [macOS](docs/macos.md): set up a new Mac, manage packages, macOS settings
- [System](docs/system.md): secrets, git, and chezmoi behavior
- [Linux](docs/linux.md): partial support notes
- [Windows](docs/windows.md): limited support

## Bootstrap (macOS)

Full steps: [Set up a new Mac](docs/macos.md#how-to-set-up-a-new-mac).

```sh
xcode-select --install   # wait for the installer to finish
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --use-builtin-git true marvindore
```
