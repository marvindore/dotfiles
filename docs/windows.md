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

## What is NOT applied on Windows

`docker/` is excluded by `.chezmoiignore`.

## XDG_CONFIG_HOME

`chezmoi apply` runs `set-xdg-config-home.ps1` once. It sets `XDG_CONFIG_HOME`
(User scope) to `%USERPROFILE%\.config` if missing; otherwise it logs
"already set — no change" and exits cleanly. Restart shells/IDEs after the
initial set so new processes pick it up.
