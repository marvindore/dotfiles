# System
## Setup ssh
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=mac

## Git remap alias
run this command: `git config --global url."git@work:WORKORG/".insteadOf "git@github.com:WORKORG/"`
to create:
```
[url "git@work:WORKORG/"]
	insteadOf = git@github.com:WORKORG/
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

### Dotnet
```
dotnet tool install -g dotnet-outdated-tool
dotnet tool install --global dotnet-ef
```

## Multiplexer
### Tmux
Install tpm
`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
then reload envionment `Ctrl-I`
### Zellij setup
```
mkdir -p ~/.config/zellij/plugins/
curl -Lo ~/.config/zellij/plugins/zellij-autolock.wasm https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm
```
Disable the mission control keyboard shortcuts for Ctl+left and Ctrl+right

## Secrets
### Bitwarden
First login then use the alias created to save the session to environment variable for use in chezmoi
```
bw login
bw_unlock
```

### Chezmoi
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

### Apple Security
    >Evaluate the two conditions up front to keep the if/else simple
    > example creation of key:
    > security add-generic-password -a GEMINI_API_KEY     -s "chezmoi_gemini_key"     -w "YOUR-GEMINI-KEY"
    > security find-generic-password -s "chezmoi_gemini_key" -w

    /usr/bin/security list-keychains
    /usr/bin/security default-keychain
    /usr/bin/security login-keychain

    security add-generic-password \
      -s company_git_org \
      -a "$USER" \
      -w <CompanyOrg> \
      -U

    ```
    -s company_git_org → service name (what keychainGet uses)
    -a "$USER" → account name (can be anything; username is typical)
    -w UKGEPIC → the actual value returned
    -U → update if it already exists
    ```

## Keyboard Remapping
### Kanata Setup
- Drivers: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice
- run daemon: `sudo '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon'`
