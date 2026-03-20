# Dotfiles

Personal dotfiles managed with chezmoi and Nix.

## Primary platform
macOS

## Docs
- docs/macos.md — full macOS bootstrap and usage
- docs/system.md — secrets, git, and chezmoi behavior
- docs/linux.md — partial support notes
- docs/windows.md — limited support

<<<<<<< Updated upstream
## Bootstrap
sh -c "$(curl -fsLS get.chezmoi.io)" -- init marvindore --apply
||||||| Stash base
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

>Evaluate the two conditions up front to keep the if/else simple
> example creation of key:
> security add-generic-password -a GEMINI_API_KEY     -s "chezmoi_gemini_key"     -w "YOUR-GEMINI-KEY"
> security find-generic-password -s "chezmoi_gemini_key" -w

/usr/bin/security list-keychains
/usr/bin/security default-keychain
/usr/bin/security login-keychain
=======
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

>Evaluate the two conditions up front to keep the if/else simple
> example creation of key:
> security add-generic-password -a GEMINI_API_KEY     -s "chezmoi_gemini_key"     -w "YOUR-GEMINI-KEY"
> security find-generic-password -s "chezmoi_gemini_key" -w

/usr/bin/security list-keychains
/usr/bin/security default-keychain
/usr/bin/security login-keychain

chezmoi secret keyring set --service litellm_api_key --user "$USER" --value "<YOUR_API_KEY>"
>>>>>>> Stashed changes
