# Installation
Install GNU stow to create symlinks
Next navigate to dotfile directory and run stow: 
```bash
cd dotfiles
stow .

# the following command will look for existing dotfiles at that location and use those to overwrite the files in this directory
stow --adopt .
```

## MACOS
- Install nix package manager
    > https://nixos.org/download/#nix-install-macos
- Ensure stow moved flake file to `.config/nix-darwin/flake.nix`
- Install nix-darwin
```bash
nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/.config/nix-darwin#mchip
```
Rebuild your config
```bash
darwin-rebuild switch --flake ~/.config/nix-darwin#mchip
```
remember by default the flakes use hostname but in our case we named config mchip

#### Finding packages with nix
website: search.nixos.org
cli: nix search <repository_from_config> <package name>
    i.e. nix search nixpkgs tmux

#### Updating packages in nix
Update packages requires two commands
```bash
nix flake update #which updates the flake.lock file
darwin-rebuild switch --flake ~/.config/nix-darwin#mchip #rebuild your config
```

## Set zsh as default shell
First view list of shells, if bash not listed and you add zsh you might find you can no longer log in as root and bash doesn't work
```bash
cat /etc/shells
# add zsh
command -v zsh | sudo tee -a /etc/shells
# now we have told terminal zsh is valid shell login, set as default
sudo chsh -s $(which zsh) $USER
```

