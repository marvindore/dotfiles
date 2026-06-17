## Project-level .env loading (multi-project credential isolation)

When working across projects with different GCP/cloud credentials, add this to the **project's** `mise.toml` to load that project's `.env` into the shell automatically when you `cd` in:

```toml
[env]
_.file = ".env"   # loads .env into the shell, overriding globals from ~/.workrc etc.
```

This solves the common problem where `~/.workrc` exports credentials for one team (e.g. payroll SA) but a project needs different credentials (e.g. a different GCP project's SA). The project `.env` wins because mise injects it at the same shell level as your global exports.

**Do NOT set `_.file = ".env"` in the global `~/.config/mise/config.toml`** — that would load any `.env` in any directory you visit, which causes surprising behaviour. Keep it project-scoped.

Alternative (Python ecosystem): `direnv` — create a `.envrc` in the project root containing `dotenv .env`. See python.md for context on when this comes up.

---

Path to executables `mise which dotnet`
mise completion – Set up completions for your shell.
mise cfg|config – A bunch of commands for working with mise.toml files via the CLI.
mise x|exec – Execute a command in the mise environment without activating mise.
mise g|generate – Generates things like git hooks, task documentation, GitHub actions, and more for your project.
mise i|install – Install tools.
mise link – Symlink a tool installed by some other means into the mise.
mise ls-remote – List all available versions of a tool.
mise ls – Lists information about installed/active tools.
mise outdated – Informs you of any tools with newer versions available.
mise plugin – Plugins can extend mise with new functionality like extra tools or environment variable management. Commonly, these are simply asdf plugins or modern plugins.
mise r|run – Run a task defined in mise.toml or mise-tasks.
mise self-update – Update mise to the latest version. Don't use this if you installed mise via a package manager.
mise settings – CLI access to get/set configuration settings.
mise rm|uninstall – Uninstall a tool.
mise up|upgrade – Upgrade tool versions.
mise u|use – Install and activate tools.
mise w|watch – Watch for changes in a project and run tasks when they occur.

mise use python@3.12.0 --global

### Paths
dotnet: ~/.local/share/mise/installs/dotnet/6.0.428/dotnet
msbuild: ~/.local/share/mise/installs/dotnet/6.0.428/sdk/6.0.428

