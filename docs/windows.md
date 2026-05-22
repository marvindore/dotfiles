# Windows

## Per-machine `chezmoi.toml` (required after `chezmoi init`)

The source tree's `<placeholder>` values come from `.chezmoidata/defaults.toml`.
Override them locally — this file is per-machine and is **not** tracked in git
(the work org slug is private):

`%USERPROFILE%\.config\chezmoi\chezmoi.toml`

```toml
[data]
profile = "work"

[data.work]
  org_slug = "YOUR_ORG_SLUG"
```

Run `chezmoi edit-config` to create/edit it. After saving, `chezmoi apply`.

## Secrets — Windows Credential Manager

The `opencode.jsonc` template reads its API key via the `keyring` template
function, keyed by service name + the username `chezmoi` sees. On a
domain-joined machine that username includes the domain prefix
(e.g. `CORPORATE_NT\marvin.dore`).

Confirm what chezmoi will look up:

```powershell
chezmoi execute-template '{{ .chezmoi.username }}'
```

Then store the entry under that exact username — use single quotes so PowerShell
preserves the backslash:

```powershell
chezmoi secret keyring set --service=litellm_api_key --user='CORPORATE_NT\marvin.dore'
```

Read it back to verify:

```powershell
chezmoi secret keyring get --service=litellm_api_key --user='CORPORATE_NT\marvin.dore'
```

## What is NOT applied on Windows

`docker/` is excluded by `.chezmoiignore`. The LiteLLM proxy runs on the home
macOS host; the Windows machine only consumes its API.

## XDG_CONFIG_HOME

`chezmoi apply` runs `set-xdg-config-home.ps1` once. It sets `XDG_CONFIG_HOME`
(User scope) to `%USERPROFILE%\.config` if missing; otherwise it logs
"already set — no change" and exits cleanly. Restart shells/IDEs after the
initial set so new processes pick it up.
