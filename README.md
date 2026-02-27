# Installation
## MACOS
First run `xcode-select --install`

- Install nix
    > https://lix.systems/install/
    > https://zero-to-nix.com/
- Or install brew and run the `macos-setup.sh script` and skip all nix steps
- If brew not found on command line add it to your path: 
    - `echo "export PATH=/opt/homebrew/bin:$PATH" >> ~/.zshrc`

## Setup nix-darwin and dotfiles
this approach pre-builds nix as your user then only uses sudo to activate as root.
This uses the build from the user so root doesn't have to rebuild maximizing cache use.
```bash
cd ~/Downloads
curl -o flake.nix https://raw.githubusercontent.com/marvindore/dotfiles/main/dot_config/nix-darwin/flake.nix
nix build ~/Downloads#darwinConfigurations.mchip.system
sudo ./result/sw/bin/darwin-rebuild switch --flake ~/Downloads#mchip
chezmoi init --apply marvindore
```

use of sudo is needed for activation(switch) step because nix-darwin needs to configure system-wide
settings like /etc defaults, /Applications, and launchd services. This creates your
"active system" under /nix/store/.. and sets up the darwin-rebuild links.

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

## Setup ssh
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=mac


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
cp "$HOME/.config/vale/.vale.ini" "$HOME/Library/Application Support/vale/"
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

### Zellij setup
```
mkdir -p ~/.config/zellij/plugins/
curl -Lo ~/.config/zellij/plugins/zellij-autolock.wasm https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm
```
Disable the mission control keyboard shortcuts for Ctl+left and Ctrl+right

### Kanata Setup
- Drivers: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice
- run daemon: `sudo '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon'`

### Typscript
Add these packages to project to fix intellisense issues
npm install --save-dev typescript-plugin-css-modules

Angular:
npm i -D @angular/language-server@15 @angular/language-service@15 typescript@~4.9

### Bitwarden
First login then use the alias created to save the session to environment variable for use in chezmoi
```
bw login
bw_unlock
```


### chezmoi helper
{{- /* Helper: read a secret by service name using macOS 'security' */ -}}
{{- define "keychainGet" -}}
  {{- $service := . -}}
  {{- (output "/bin/sh" "-c" (printf "/usr/bin/security find-generic-password -s %q -w 2>/dev/null || true" $service)) | trim -}}
{{- end -}}

>Evaluate the two conditions up front to keep the if/else simple
>example creation of key:
>security add-generic-password -a GEMINI_API_KEY     -s "chezmoi_gemini_key"     -w "YOUR-GEMINI-KEY"
>security find-generic-password -s "chezmoi_gemini_key" -w
{{- $useKeychain := and (env "CHEZMOI_SECRETS") (env "CHEZMOI_WORK") (lookPath "security") -}}
{{- $useBW       := and (env "CHEZMOI_SECRETS") (lookPath "bw") -}}

{{- if $useKeychain -}}
GEMINI_API_KEY=""
LITELLM_MASTER_KEY="{{ template "keychainGet" "chezmoi_litellm_master" }}"
{{end}}
