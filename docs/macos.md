# MACOS
## Prequisites
`xcode-select --install`

## Package Manager Options
### Homebrew
Install homebrew using: https://brew.sh/
- run the `macos-setup.sh script` 
- If brew not found on command line add it to your path: 
    - `echo "export PATH=/opt/homebrew/bin:$PATH" >> ~/.zshrc`

### Nix
- Choose one of the following nix install paths
    > https://lix.systems/install/ # Lix
    > https://zero-to-nix.com/     # Determinate Systems

- Setup nix-darwin and dotfiles
    this approach pre-builds nix as your user then only uses sudo to activate as root.
    This uses the build from the user so root doesn't have to rebuild maximizing cache use.
    ```bash
    cd ~/Downloads
    curl -o flake.nix https://raw.githubusercontent.com/marvindore/dotfiles/main/dot_config/nix-darwin/flake.nix
    nix build ~/Downloads#darwinConfigurations.mchip.system
    sudo ./result/sw/bin/darwin-rebuild switch --flake ~/Downloads#mchip
    chezmoi init --apply marvindore
    ```

>use of sudo is needed for activation(switch) step because nix-darwin needs to configure system-wide
>settings like /etc defaults, /Applications, and launchd services. This creates your
>"active system" under /nix/store/.. and sets up the darwin-rebuild links.

```bash
# rebuild config
darwin-rebuild switch --flake ~/.config/nix-darwin#mchip
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
darwin-rebuild switch --flake ~/.config/nix-darwin#mchip 
```
