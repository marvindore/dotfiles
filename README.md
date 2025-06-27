# Installation
## MACOS
First run `xcode-select --install`

- Install nix
    > https://zero-to-nix.com/
- Or install brew and run the `macos-setup.sh script` and skip all nix steps
- If brew not found on command line add it to your path: 
    - `echo "export PATH=/opt/homebrew/bin:$PATH" >> ~/.zshrc`

** Install nix-darwin**
```bash
cd ~/Downloads
curl -LJO https://raw.githubusercontent.com/marvindore/dotfiles/refs/heads/main/.config/nix-darwin/flake.nix
nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/Downloads#mchip
```

** Setup ssh**
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=mac

**Use GNU stow to setup symlinks** 
```bash
cd dotfiles
stow .

# the following command will look for existing dotfiles at that location and use those to overwrite the files in this directory
stow --adopt .
```
Now that symlinks are created, use the flake from the dotfiles
```bash
nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/.config/nix-darwin#mchip
# Rebuild config
darwin-rebuild switch --flake ~/dotfiles/.config/nix-darwin#mchip 
```
remember by default the flakes use hostname but in our case we named config mchip

#### Finding packages with nix
- website: search.nixos.org
- cli: nix search <repository_from_config> <package name>
    i.e. nix search nixpkgs tmux

#### Updating packages in nix
Update packages requires two commands
```bash
nix flake update #which updates the flake.lock file
#rebuild your config
darwin-rebuild switch --flake ~/dotfiles/.config/nix-darwin#mchip 
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

Setup Vale on MacOS
```bash
cp ~/dotfiles/.config/vale/.vale.ini "~/Library/Application Support/vale/"
~/.local/share/nvim/mason/packages/vale/vale --config="$HOME/Library/Application Support/vale/.vale.ini" sync
```
Linux
```
vale --config="$HOME/.config/vale/.vale.ini" sync
```

### Tmux
Install tpm
`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
then reload envionment `Ctrl-I`


### Dotnet
```
dotnet tool install -g dotnet-outdated-tool
dotnet tool install --global dotnet-ef
```
