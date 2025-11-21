# Installation
## MACOS
First run `xcode-select --install`

- Install nix
    > https://lix.systems/install/
    > https://zero-to-nix.com/
- Or install brew and run the `macos-setup.sh script` and skip all nix steps
- If brew not found on command line add it to your path: 
    - `echo "export PATH=/opt/homebrew/bin:$PATH" >> ~/.zshrc`

** Install nix-darwin**
this approach pre-builds nix as your user then only uses sudo to activate as root.
This uses the build from the user so root doesn't have to rebuild maximizing cache use.
```bash
cd ~/Downloads
curl -LJO https://raw.githubusercontent.com/marvindore/dotfiles/refs/heads/main/.config/nix-darwin/flake.nix
nix build ~/Downloads#darwinConfigurations.mchip.system
sudo ./result/sw/bin/darwin-rebuild switch --flake ~/Downloads#mchip
```
use of sudo is needed for initial setup because nix-darwin needs to configure system-wide
settings like /etc defaults, /Applications, and launchd services. This creates your
"active system" under /nix/store/.. and sets up the darwin-rebuild links.

```bash
# rebuild config
darwin-rebuild switch --flake ~/dotfiles/.confid/nix-darwin#mchip
```
the rebuild usually doesn't need sudo each time unless you update system aliases/defaults.


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

mkdir -p ~/.config/zellij/plugins/
curl -LO https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm
