# macOS

Provisioning is split by ownership. Each tool does the job it is designed for.

| Layer | Owns | Where |
|---|---|---|
| chezmoi | files in `$HOME`, machine differences, the coordinator scripts | this repo |
| Homebrew Bundle | installed software: taps, formulae, casks, Mac App Store apps | `~/.config/homebrew/Brewfile` |
| one `run_onchange_` script | macOS `defaults` and Dock restart | `.chezmoiscripts/run_onchange_after_11-macos-defaults.sh.tmpl` |
| mise | language runtimes and CLIs: node, pnpm, uv, java, kubectl | `~/.config/mise/config.toml` |
| two scripts | C toolchain check, then headless Neovim plugin and parser install | `.chezmoiscripts/run_after_13-check-toolchain.sh.tmpl`, `.chezmoiscripts/run_onchange_after_14-nvim-bootstrap.sh.tmpl` |
| gh | gh extensions | `.chezmoiscripts/run_onchange_after_30-gh-extensions.sh.tmpl` |

The daily command is `chezmoi apply`. It deploys changed files only, and runs a script only when that script's rendered content changed since its last successful run. From Claude Code, run it as `! chezmoi apply`, so that sudo prompts reach you.

## How-to: set up a new Mac

### Before you start

1. Install the Xcode Command Line Tools. Wait until the installer window reports that it is done:

   ```sh
   xcode-select --install
   ```

   This installs git, the compilers, and the other build tools that Homebrew needs.
2. Home profile only: open the App Store and sign in. Then click Get once for Pages, Numbers, and WireGuard. `mas` can install only apps that your Apple ID already owns.

### Run the setup

3. Open Terminal in your home folder and run one of these commands:

   **Home profile:**

   ```sh
   cd ~
   sudo -v   # cache sudo now, so the Homebrew step does not stop to ask
   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --use-builtin-git true marvindore
   ```

   **Work profile:**

   ```sh
   cd ~
   sudo -v   # cache sudo now, so the Homebrew step does not stop to ask
   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --use-builtin-git true marvindore \
     --promptChoice "Profile=work" \
     --promptString "Work org slug=<slug>,Work email=<email>,SilverBullet space path=<path>"
   ```

   Both commands install a temporary chezmoi in `~/bin`, clone this repo, and apply everything. The home command prompts for the profile only (type `home`). The work command is non-interactive.

   The flags match the prompt text in `.chezmoi.toml.tmpl`, not the key name. If you change a prompt text, change these commands too.

   `--use-builtin-git true` is a safeguard. If step 1 did not finish, chezmoi uses its built-in git instead of the `/usr/bin/git` placeholder. The flag applies to these commands only.

4. Answer the prompts while the command runs:
   - Your password, when the Homebrew step starts, unless `sudo -v` is still cached. Homebrew asks again when an install takes longer than the sudo timeout, which is 5 minutes by default.
   - Your password again when a cask must copy an app into `/Applications` with sudo. On managed Macs this happens for GitButler. If sudo asks "Confirm Operation", answer `Yes`.
   - Work profile only: type `YES` to accept the Microsoft ODBC driver license for `msodbcsql17`.
   - Home profile only: your password for the Google Drive installer.

   What runs, in order:
   - `00-install-homebrew` installs Homebrew when it is missing. It runs `sudo -v` first, then the Homebrew installer.
   - chezmoi deploys the files.
   - `10-brew-bundle` runs `brew bundle check`, then `brew bundle install` only when something is missing.
   - `11-macos-defaults` writes the settings that differ, then restarts the Dock only if a Dock key changed.
   - `12-mise-install` runs `mise install` for the tools in `~/.config/mise/config.toml`.
   - `13-check-toolchain` compiles and links a small C program. When the Command Line Tools linker does not match the SDK, it stops the apply and prints the repair steps. It runs on every apply.
   - `14-nvim-bootstrap` starts Neovim headless once. It installs the plugins and builds the tree-sitter parsers, so that the first interactive `nvim` start shows no errors. It reruns when the parser list in `dot_config/nvim/lua/utils/ts_langs.lua` changes.
   - `20-install-hammerspoon-spoons` installs the RecursiveBinder Spoon when it is missing or has no `init.lua`. It runs on every apply and prints nothing when the Spoon is present. A failed download prints a warning and does not stop the apply.
   - `30-gh-extensions` installs the gh extensions. On a new Mac it skips, because `gh` is not logged in yet. See step 8.
   - Work profile only: `start-silverbullet` starts colima if Docker is not running, then syncs the config repo. It deploys SilverBullet only when the repo, the settings, or the container state changed, or when the last image pull is 7 or more days old. The home profile uses the homelab SilverBullet.

5. If the command stops with an error, fix the cause and run `chezmoi apply`. A failed script stops the scripts after it, and `chezmoi apply` runs it again. The usual cause is a Mac App Store app that your Apple ID does not own yet. See step 2. If `13-check-toolchain` fails, see [fix the parser build](#how-to-fix-neovim-parser-build-fails-with-ld-tapi-error).

### After the setup

6. Close Terminal and open a new terminal. Make sure that the Homebrew chezmoi is in use, then delete the temporary copy:

   ```sh
   which chezmoi    # expected: /opt/homebrew/bin/chezmoi
   rm ~/bin/chezmoi
   ```

7. Fill in the private values in `~/.config/chezmoi/chezmoi.toml`. chezmoi wrote this file in step 3. Replace every `<place_holder>` with the real value. See [chezmoi.toml template](#chezmoitoml-template) for each key and where to find its value. Then apply:

   ```sh
   chezmoi edit-config   # or open ~/.config/chezmoi/chezmoi.toml in any editor
   chezmoi apply
   ```

   Home profile: `silverbulletUrl` is the only placeholder. Until you set it, alt+n in Hammerspoon shows an alert instead of opening SilverBullet.

   To skip this step on the next Mac, create the file from the template before step 3. `chezmoi init` keeps the values that are already in the file and does not prompt for them.
8. Log in to GitHub, then apply again. The gh extension script sees the login and installs `gh-dash`:

   ```sh
   gh auth login
   chezmoi apply
   ```

9. Open AeroSpace, Hammerspoon, Espanso, Scoot, and Thaw once. Give each one the Accessibility permission in System Settings, Privacy & Security, when macOS asks.
   Optional: for the Hammerspoon Bookmarks (leader s, b) and URL Builder (leader s, u) pickers, copy `~/.hammerspoon/data/bookmarks.example.json` to `bookmarks.json` and `url-templates.example.json` to `url-templates.json`, then edit them. chezmoi does not manage the copies, so they stay on the machine.
10. Create your SSH keys, `~/.ssh/home` for personal and `~/.ssh/work` for work, and add the public keys to GitHub. Then switch the repo remote to SSH. `home` is the host alias in `~/.ssh/config` that uses your personal key:

   ```sh
   chezmoi git -- remote set-url origin git@home:marvindore/dotfiles.git
   ```

11. Log out and log in again. `NSGlobalDomain KeyRepeat` takes effect only after a new login.
12. `GuestEnabled` needs sudo. The defaults script skips it when sudo is not cached and prints the command to run by hand. On a first setup the sudo cache from the Homebrew step has usually expired by then, so expect to run it:

    ```sh
    sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    ```

## How-to: add, upgrade, or audit packages

Shell shortcuts from `dot_aliases`:

| Command | Does |
|---|---|
| `brewfile` | edit the Brewfile template, then apply (installs anything new) |
| `bbi` | install everything missing from the Brewfile, no upgrades |
| `bbc` | list what the Brewfile declares but is not installed |
| `bbx` | list installed packages not in the Brewfile, never removes |
| `bbclean` | remove installed packages not in the Brewfile |
| `bbs` | sync: install everything missing, then remove extras, no upgrades |
| `brewup` | upgrade everything, then reconcile with the Brewfile |

Use `bbi` after uninstalling something by hand. `chezmoi apply` reruns brew bundle only when the Brewfile changes.

The raw commands follow.

Add or remove software:

```sh
chezmoi edit ~/.config/homebrew/Brewfile   # edits dot_config/homebrew/Brewfile.tmpl
chezmoi apply                              # reruns brew bundle because the Brewfile hash changed
```

Third-party taps need the full name and `trusted: true` (Homebrew 7 tap trust):

```ruby
brew "microsoft/mssql-release/msodbcsql17", trusted: true
cask "nikitabobko/tap/aerospace", trusted: true
```

Upgrade everything, then reconcile with the Brewfile:

```sh
brewup   # brew update && brew upgrade && brew bundle install --global && brew cleanup
```

Audit:

```sh
brew bundle check --no-upgrade --verbose --global   # what is missing
brew bundle cleanup --global           # dry run: lists extras not in the Brewfile, removes nothing
chezmoi verify                         # files on disk match the source
chezmoi doctor                         # chezmoi environment check
```

`brew bundle cleanup --force` (`bbclean`, `bbs`) removes only packages that Homebrew installed. It does not touch apps installed by hand or from a `.pkg`, and it does not remove Mac App Store apps. Each Mac compares against its own rendered Brewfile, so home and work keep their own lists. Check that `profile` in `~/.config/chezmoi/chezmoi.toml` is correct before you run it: a wrong profile removes every app of the other profile. Run `bbx` first to see the list. Cleanup does not use `--zap`, so app settings in `~/Library` stay.


## How-to: reapply macOS settings or rerun a script

`chezmoi apply` runs a `run_onchange_` script only when its rendered content changed. A setting changed in System Settings is not reset, because the script did not change. `chezmoi apply --include=scripts` does not help either: it also skips unchanged scripts.

Reapply all macOS settings now:

```sh
chezmoi execute-template < "$(chezmoi source-path)/.chezmoiscripts/run_onchange_after_11-macos-defaults.sh.tmpl" | sh
```

The script prints one line for each setting it corrects. It prints nothing when every setting matches. It is safe to run at any time.

The same pattern works for any chezmoi script. Render it with `chezmoi execute-template`, then pipe it to `sh`. Reinstall missing packages with `bbi` instead.

Rerun scripts on the next apply. chezmoi keeps the state of the two script types in different buckets:

```sh
chezmoi state delete-bucket --bucket=scriptState   # run_once_ scripts
chezmoi state delete-bucket --bucket=entryState    # run_onchange_ scripts
chezmoi apply
```

`entryState` also holds the state of every managed file. After you delete it, chezmoi can no longer detect files that changed on disk since its last write. Use the `execute-template` method above when you need to rerun only one script.

## How-to: change a local, private value

Private values (profile, work org slug, work email, SilverBullet path or URL) live in `~/.config/chezmoi/chezmoi.toml`. That file is not tracked. `.chezmoi.toml.tmpl` in the repo holds only the prompts.

- Edit the local file directly, then `chezmoi apply`.
- Add a new local key: add it to `.chezmoi.toml.tmpl` first, either as a `promptStringOnce` line (prompted) or as a `dig "<key>" "<place_holder>" .` line (not prompted, placeholder until you edit it). Add the key to the [chezmoi.toml template](#chezmoitoml-template) too. `chezmoi init` regenerates the local file from the template and drops keys that are not in it.
- `chezmoi init` without arguments regenerates the local file. Existing values are reused and nothing is prompted.

## How-to: fix "Neovim parser build fails with ld: tapi error"

Symptom: the first `nvim` start prints `[nvim-treesitter/install/<lang>] error: ... ld: tapi error: malformed file ... unknown architecture`, or `13-check-toolchain` stops `chezmoi apply`.

Cause: the linker in the Command Line Tools (CLT) is older than the macOS SDK that it links against. The SDK lists a CPU slice that the linker does not know. This happens when Migration Assistant restores an old CLT, when a CLT update was interrupted, or when `xcode-select` points to an old Xcode.

1. Collect the facts:

   ```sh
   xcode-select -p
   ld -v 2>&1 | head -1
   xcrun --show-sdk-path; xcrun --show-sdk-version
   pkgutil --pkg-info=com.apple.pkg.CLTools_Executables | grep version
   ```

   The CLT package version and the SDK version must match, for example both `27.0`.
2. Install the pending CLT update, if Apple lists one:

   ```sh
   softwareupdate --list 2>&1 | grep -i 'command line tools'
   sudo softwareupdate --install "<label from the list>"
   ```

3. If no update is listed, reinstall the CLT. Wait until the installer window reports that it is done:

   ```sh
   sudo rm -rf /Library/Developer/CommandLineTools
   xcode-select --install
   ```

4. If `xcode-select -p` shows an `Xcode.app`, point it to the CLT:

   ```sh
   sudo xcode-select -s /Library/Developer/CommandLineTools
   ```

5. Run `chezmoi apply`. The toolchain check passes, then the Neovim bootstrap builds the parsers. Inside Neovim, `:TSBootstrap` does the same build by hand.

## Reference

### Brewfile

`dot_config/homebrew/Brewfile.tmpl` renders to `~/.config/homebrew/Brewfile`. Homebrew reads this path for `--global` because `XDG_CONFIG_HOME` is set in `.zshenv`. Sections: taps, formulae, casks, an opt-in comment block, then `{{ if eq .profile "work" }}` and `{{ if eq .profile "home" }}` blocks. The home block contains the Mac App Store apps.

### mise

`dot_config/mise/config.toml` renders to `~/.config/mise/config.toml`. Edit it with `chezmoi edit ~/.config/mise/config.toml`, then `chezmoi apply` reruns `mise install`. If you ran `mise use -g <tool>` instead, run `chezmoi re-add ~/.config/mise/config.toml` so the repo gets the change.

### Scripts

| Script | Type | Reruns when |
|---|---|---|
| `run_once_before_00-install-homebrew.sh.tmpl` | once, before files | its own content changes |
| `run_onchange_after_10-brew-bundle.sh.tmpl` | on change, after files | the rendered Brewfile changes (hash in a comment) or the profile changes |
| `run_onchange_after_11-macos-defaults.sh.tmpl` | on change, after files | its own content changes |
| `run_onchange_after_12-mise-install.sh.tmpl` | on change, after files | the mise config changes (hash in a comment) |
| `run_after_13-check-toolchain.sh.tmpl` | always, after files | every apply; it stops the apply when `cc` cannot link |
| `run_onchange_after_14-nvim-bootstrap.sh.tmpl` | on change, after files | the parser list `dot_config/nvim/lua/utils/ts_langs.lua` changes (hash in a comment) |
| `run_after_20-install-hammerspoon-spoons.sh` | always, after files | every apply; it installs only when the Spoon is missing |
| `run_after_start-silverbullet.sh.tmpl` | always, after files | every apply; it deploys only when the repo SHA, the `.env`, or the container state changed, or the image pull is 7 or more days old |
| `run_onchange_after_30-gh-extensions.sh.tmpl` | on change, after files | the extension list or the stored `gh` token changes |

All of them are idempotent on their own. Running them twice changes nothing. The `run_after_` scripts `13-check-toolchain` and `20-install-hammerspoon-spoons` run on every apply so that they detect and repair breakage. Each one checks first and stays silent when nothing is wrong. Scripts are ordered by target name with prefixes stripped: `00-`, `10-`, `11-`, `12-`, `13-`, `14-`, `20-install-hammerspoon-spoons`, `30-gh-extensions`, `start-silverbullet`.

The bundle script sets `HOMEBREW_BUNDLE_NO_UPGRADE=1` and `HOMEBREW_NO_AUTO_UPDATE=1`, and passes `--no-upgrade` to `brew bundle check`. The env var stops `install` from upgrading, but `check` ignores it: without the flag, `check` treats outdated formulae as unsatisfied. Upgrades belong to `brewup`.

### macOS defaults

| Domain | Key | Value |
|---|---|---|
| `com.apple.dock` | `autohide` | true |
| `com.apple.dock` | `appswitcher-all-displays` | true |
| `com.apple.dock` | `persistent-apps` | empty (no pinned apps) |
| `NSGlobalDomain` | `KeyRepeat` | 2 |
| `com.apple.WindowManager` | `EnableStandardClickToShowDesktop` | false |
| `/Library/Preferences/com.apple.loginwindow` | `GuestEnabled` | false (sudo) |

Every write is preceded by a read and happens only when the value differs. The Dock reset acts only when pinned apps exist.

### Local config keys

| Key | Profile | Prompt | Used by |
|---|---|---|---|
| `profile` | both | choice: home, work | Brewfile blocks, `.chezmoiignore`, work-only scripts |
| `silverbulletSpacePath` | work | string | `start-silverbullet` script |
| `silverbulletUrl` | home | none, placeholder | Hammerspoon alt+n (`dot_hammerspoon/init.lua.tmpl`) |
| `work.org_slug` | work | string | work git and SSH templates |
| `work.email` | work | string | work git templates |

### chezmoi.toml template

`~/.config/chezmoi/chezmoi.toml` is not tracked. Copy the block for your profile. Keep the `[merge]` section that `chezmoi init` wrote.

Home:

```toml
[data]
profile = "home"
silverbulletUrl = "<place_holder>"   # address of the homelab SilverBullet, as you open it in the browser, e.g. https://notes.example.lan
```

Work:

```toml
[data]
profile = "work"
silverbulletSpacePath = "<place_holder>"   # folder for the notes, e.g. "$HOME/OneDrive - <Company>/notes". Created if missing.

[data.work]
  org_slug = "<place_holder>"   # GitHub org in work repo URLs: github.com/<org_slug>/...
  email = "<place_holder>"      # work email for git commits
```

Check a value with `chezmoi execute-template '{{ .silverbulletUrl }}'`. A key that is missing falls back to the `<place_holder>` default in `.chezmoidata.yaml`.

### Homebrew without chezmoi

The Brewfile and the defaults script contain no chezmoi logic beyond the OS and profile guards. To use them elsewhere: install Homebrew, copy `~/.config/homebrew/Brewfile`, run `brew bundle install --global`, and run the rendered defaults script.
