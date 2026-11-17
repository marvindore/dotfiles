# Windows

Windows uses the work profile. chezmoi owns the files in `%USERPROFILE%`. The
software list is in `scripts/windows-setup.ps1` (Scoop and winget).

The daily command is `chezmoi apply`. It deploys changed files only.

## How-to: set up a new Windows PC

### Before you start

1. Make sure that `winget` works. It comes with App Installer from the
   Microsoft Store:

   ```powershell
   winget --version
   ```

2. Install the tools that `.gitconfig` calls. See [Prerequisites](#prerequisites).

### Run the setup

3. Open PowerShell in your home folder and run one of these commands:

   **winget:**

   ```powershell
   cd ~
   winget install --id twpayne.chezmoi -e
   # Open a new PowerShell, so that chezmoi is on PATH
   chezmoi init --apply marvindore `
     --promptChoice "Profile=work" `
     --promptString "Work org slug=<slug>,Work email=<email>,SilverBullet space path=<path>"
   ```

   **No winget (download):**

   ```powershell
   cd ~
   (irm -useb https://get.chezmoi.io/ps1) | powershell -c -
   ./bin/chezmoi init --apply marvindore `
     --promptChoice "Profile=work" `
     --promptString "Work org slug=<slug>,Work email=<email>,SilverBullet space path=<path>"
   ```

   The download command puts a temporary chezmoi in `~\bin`. The winget
   command installs chezmoi for good.

   The flags match the prompt text in `.chezmoi.toml.tmpl`, not the key name.
   If you change a prompt text, change these commands too. `<path>` is
   required by the prompt, but the Windows setup does not use it.

   What runs: chezmoi deploys the files, then `set-xdg-config-home.ps1` sets
   the User environment variables. See
   [User environment variables](#user-environment-variables).

4. If the command stops with an error, fix the cause and run `chezmoi apply`.

### After the setup

5. Download-method only: delete the temporary copy, then install chezmoi with
   winget:

   ```powershell
   Remove-Item ~\bin\chezmoi.exe
   winget install --id twpayne.chezmoi -e
   ```

6. Fill in the private values. See [Per-machine chezmoi.toml](#per-machine-chezmoitoml).
7. Sign in to GitHub. See [GitHub sign-in](#github-sign-in).
8. Restart shells, IDEs, and Espanso, so that they get the new environment
   variables.

## Per-machine `chezmoi.toml`

chezmoi writes this file at `chezmoi init`. Replace the `<place_holder>` values
from `.chezmoidata.yaml` with real values. The file is per-machine and is
**not** tracked in git. See "Chezmoi per-machine config" in `docs/system.md`.

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

- `delta` (git pager): `winget install dandavison.delta`
- `difft` (difftastic, git difftool): `scoop install difftastic`
- `nvim` (chezmoi merge tool): `winget install Neovim.Neovim.Nightly`
- `gh` (git credential helper for HTTPS): `winget install GitHub.cli`

To install the full software list, run `scripts/windows-setup.ps1`.

## GitHub sign-in

Do this one time on each machine. Git uses this login for HTTPS remotes. Sign
in with your work GitHub account:

```powershell
gh auth login --hostname github.com --git-protocol https --web
```

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
