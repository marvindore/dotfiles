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

### Chezmoi per-machine config

The repo's `<placeholder>` data values come from `.chezmoidata/defaults.toml`.
Override them locally in `~/.config/chezmoi/chezmoi.toml` — this file is
per-machine and is intentionally NOT tracked in git (work org slug is private):

```toml
[data]
profile = "work"   # or "home"

[data.work]
  org_slug = "YOUR_ORG_SLUG"
```

Run `chezmoi edit-config` to create/edit. Re-run `chezmoi apply` after.

OS-specific secret storage:
- macOS: see "Apple Security" below.
- Windows: see `docs/windows.md`.

### Scriptkit
** bookmarks **
 cat > ~/.scriptkit/plugins/main/scripts/_lib/bookmarks.local.json << 'EOF'
  [
    { "name": "Confluence", "url": "https://your-org.atlassian.net/wiki", "keywords": "docs wiki" },
    { "name": "Jira", "url": "https://your-org.atlassian.net/jira", "keywords": "tickets issues" }
  ]
  EOF

### Apple Security (macOS Keychain)

Service names referenced by the current templates:

| Service              | Used by                          | Required on             |
|----------------------|----------------------------------|-------------------------|
| `litellm_api_key`    | `dot_config/opencode/opencode.jsonc.tmpl` (via `keyring`) | every machine that runs opencode |
| `gemini_api_key`     | `docker/litellm/dot_env.tmpl`    | home (LiteLLM proxy host) only |
| `litellm_master_key` | `docker/litellm/dot_env.tmpl`    | home (LiteLLM proxy host) only |

Create entries:

```bash
security add-generic-password -a "$USER" -s "litellm_api_key"    -w "YOUR-LITELLM-KEY" -U
security add-generic-password -a "$USER" -s "gemini_api_key"     -w "YOUR-GEMINI-KEY"  -U
security add-generic-password -a "$USER" -s "litellm_master_key" -w "YOUR-MASTER-KEY" -U
```

Flags: `-s` service name, `-a` account (the `keyring` template func uses
`.chezmoi.username` which is your login name on macOS), `-w` value,
`-U` update if exists.

Read back / inspect:

```bash
security find-generic-password -s "litellm_api_key" -w
/usr/bin/security list-keychains
/usr/bin/security default-keychain
```

Unrelated: storing the work org slug in Keychain for shell use:

```bash
security add-generic-password -s company_git_org -a "$USER" -w "<CompanyOrg>" -U
```

## Keyboard Remapping
### Kanata Setup
- Drivers: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice
- run daemon: `sudo '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon'`
