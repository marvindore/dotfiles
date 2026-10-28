# Windows

## Per-machine `chezmoi.toml` (required after `chezmoi init`)

Replace the `<place_holder>` values from `.chezmoidata.yaml` with real values in
this file. It is per-machine and is **not** tracked in git. See "Chezmoi
per-machine config" in `docs/system.md`.

`%USERPROFILE%\.config\chezmoi\chezmoi.toml`

```toml
[data]
profile = "work"

[data.work]
  org_slug = "YOUR_ORG_SLUG"
  email = "you@your-company.com"
```

Run `chezmoi edit-config` to create/edit it. After saving, `chezmoi apply`.

## Prerequisites

Install these tools before `chezmoi apply`. `.gitconfig` calls them:

- `delta` (git pager)
- `difft` (difftastic, git difftool)
- `nvim` (chezmoi merge tool)

## What is NOT applied on Windows

`.chezmoiignore` excludes these targets on Windows:

- macOS only: `.hammerspoon/`, `.config/aerospace/`, `.colima/`, `.config/homebrew/`
- Linux only: `.config/hypr/`, `.config/waybar/`, `.config/wofi/`, `scripts/*.sh`
- Not used on Windows: `docker/`, `.config/alacritty/`, `.config/helix/`,
  `.config/ghostty/`, `.config/tmux/`, `.config/zsh/`, `.zshenv`,
  `.local/bin/tmux-workspace`, `.local/bin/wezterm-jump`,
  `scripts/windows-setup.ps1`

The macOS `.sh` scripts in `.chezmoiscripts/` render empty on Windows, so
chezmoi skips them.

## Line endings

`.gitattributes` keeps all files LF, and `.cmd`, `.bat`, `.ps1` files CRLF.
You do not need to change `core.autocrlf`.

## Symlinks

The source has no `symlink_` entries. If you add one, Windows needs Developer
Mode (Settings > System > For developers) or an elevated shell. Otherwise
`chezmoi apply` fails with "A required privilege is not held by the client".

## User environment variables

`chezmoi apply` runs `set-xdg-config-home.ps1` on every apply. It sets these
User variables only if they are missing:

- `XDG_CONFIG_HOME` = `%USERPROFILE%\.config`
- `ESPANSO_CONFIG_DIR` = `%USERPROFILE%\.config\espanso` (Espanso ignores
  `XDG_CONFIG_HOME` on Windows)

If a variable is already set, the script logs "already set - no change". Restart
shells, IDEs, and Espanso after the first set, so that new processes get the
values.

Keep the script ASCII-only. Windows PowerShell 5.1 reads files without a BOM as
cp1252, and some UTF-8 characters then break the parse.
