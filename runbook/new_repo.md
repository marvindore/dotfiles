# Developer Workflow Convention for Every Repository

This is a career-durable pattern for establishing a developer interface that answers: **How do I set this up, run it, test it, and debug it?**

The key principle: **Workflows must be version-controlled with the code, not locked in personal dotfiles.**

## Why This Matters

A durable developer interface:
- Survives editor changes (works with CLI, Neovim, VS Code, terminal, CI)
- Works offline and doesn't depend on a project management app
- Remains discoverable as the codebase evolves
- Teammates can understand and use it immediately
- CI pipelines use the exact same commands as local development

## File Responsibilities

Every repository should include these files in the root directory:

| File | Responsibility |
|------|-----------------|
| **README.md** | Human-readable orientation and the first commands to run |
| **mise.toml** | Required language runtimes, CLI tools, and safe environment defaults |
| **justfile** | The canonical interface for setup, run, test, lint, build, and debug |
| **.vscode/launch.json** | Debug Adapter Protocol configurations for IDE debugging |
| **.env.example** | Template for required environment variables (never secrets) |
| **docs/development.md** | Unusual workflows, architecture notes, troubleshooting |

### README.md

Keep it short. Link to the command interface, not duplicate it.

**Template:**
```markdown
# Project Name

Brief description of what this project does.

## Quick Start

```bash
mise install
cp .env.example .env
just setup
just dev
```

## Common Commands

```bash
just
just doctor
just run
just test
just check
```

See `.vscode/launch.json` for debugging configurations.

For architecture, workflows, and troubleshooting, see `docs/development.md`.
```

### mise.toml

Declares required tools and versions. Never commit secrets—use `.env` for those.

**Example (Node.js):**
```toml
[tools]
node = "22.23.1"
npm = "10.1.0"
just = "latest"

[env]
NODE_ENV = "development"
_.file = ".env"
```

**Example (Rust):**
```toml
[tools]
rust = "stable"
cargo-watch = "latest"
just = "latest"

[env]
_.file = ".env"
```

### justfile

The command menu. `just --list` should show all available workflows.

**Standardized recipes (implement all):**

```bash
set dotenv-load := true

# Display available commands
default:
    @just --list

# Verify that development environment is usable
doctor:
    @echo "Checking development environment..."
    @mise doctor
    @command -v git >/dev/null || { echo "ERROR: git not found"; exit 1; }
    @test -f .env || echo "NOTICE: .env is missing; copy .env.example and fill it in"
    @echo "Environment check complete."

# First-time, idempotent project setup
setup:
    mise install
    # Add package installation or bootstrap steps here

# Run the application normally
run:
    echo "TODO: define the run command"

# Run with development conveniences such as file watching
dev:
    echo "TODO: define the development command"

# Start in a debugger-friendly mode
debug:
    @echo "Open your editor and start the 'Application' debug configuration."
    @echo "See .vscode/launch.json and docs/development.md for details."

# Run the normal test suite
test:
    echo "TODO: define the test command"

# Run one test or test filter
test-one filter:
    echo "TODO: run tests matching '{{filter}}'"

# Run formatting, linting, type checks, and fast tests
check:
    just format-check
    just lint
    just test

format:
    echo "TODO: define the formatter"

format-check:
    echo "TODO: verify formatting without changing files"

lint:
    echo "TODO: define linting"

build:
    echo "TODO: define the build command"

clean:
    echo "TODO: safely remove generated output"

# Approximate the checks performed by CI
ci:
    just check
    just build
```

**Suggested semantics:**

- **doctor:** Validate system dependencies, environment variables, services, and credentials. Run this when something breaks.
- **setup:** Perform idempotent first-time setup (install dependencies, initialize databases, etc.).
- **run:** Run the application at its default entry point.
- **dev:** Run in watch/reload mode for rapid feedback.
- **debug:** Start in a debugger-friendly mode or print debugger instructions.
- **test:** Run the complete test suite.
- **test-one `<filter>`:** Run a single test or filtered test suite.
- **check:** Fast validation (formatting, linting, type checks, unit tests). Should run before committing.
- **ci:** Reproduce the important CI pipeline locally.

### .env.example

Document required environment variables with examples. Never include actual secrets.

**Template:**
```bash
# Application configuration
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/mydb

# Third-party services
API_KEY=sk_test_xxxxxxxxxxxxx
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx

# Development tools
DEBUG=*
```

### .vscode/launch.json

Debug Adapter Protocol configurations. Works with Neovim (`nvim-dap`), VS Code, and other DAP clients.

**Template:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Application",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/index.js",
      "cwd": "${workspaceFolder}"
    },
    {
      "name": "Attach to Application",
      "type": "node",
      "request": "attach",
      "port": 9229
    }
  ]
}
```

See language-specific DAP documentation for your debugger type:
- **Node.js:** `node` or `pwa-node`
- **.NET:** `coreclr` (netcoredbg)
- **Python:** `python` (debugpy)
- **Go:** `delve`
- **Rust:** `codelldb`

### docs/development.md

Unusual workflows, architecture decisions, and troubleshooting. Link to this from README.

**Typical sections:**

- Project structure (directory organization, naming conventions)
- External services (what runs locally, what runs remotely)
- Database setup and migrations
- Testing approach (unit vs. integration, mocking strategies)
- Code style and patterns
- Common issues and solutions
- Links to related documentation

**Example outline:**
```markdown
# Development Guide

## Architecture

Brief overview of components and their relationships.

## Services

Services that must run locally:
- PostgreSQL on localhost:5432
- Redis on localhost:6379
- Mock server on localhost:3001

## Database

### Migrations

```bash
just migrate
```

### Seeding

```bash
just seed
```

## Testing

### Unit Tests

```bash
just test
```

### Integration Tests

Require local services running.

```bash
just test-integration
```

## Troubleshooting

### Issue: Tests fail with "Connection refused"

Ensure services are running:
```bash
docker compose up
```

### Issue: "Port 3000 already in use"

Kill the process:
```bash
lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

## References

- [Architecture Decision Records](./adr)
- [API Documentation](./docs/api.md)
- [Database Schema](./schema.sql)
```

## Neovim Integration

### Using Overseer.nvim

Overseer discovers and runs tasks from `justfile` and `mise.toml`. In Neovim:

- `<leader>or` — Select and run a task
- `<leader>ot` — Toggle task list (shows running, completed, failed)
- `<leader>ol` — Restart the last task
- `<leader>oa` — Perform an action on a task (restart, stop, dispose)

This keeps the source of truth in your repository's `justfile`, not your editor config.

### Using nvim-dap for Debugging

1. Create `.vscode/launch.json` in your repository (this file is read by nvim-dap)
2. In Neovim:
   - Press `F5` to start debugging
   - Press `<F10>` to step over, `<F11>` to step into
   - Press `<leader>db` to toggle breakpoints
3. No editor-specific configuration needed—it works anywhere DAP is supported

## Architecture Philosophy

Your Neovim config should provide generic actions:

✅ **Correct:**
```lua
vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<cr>", { desc = "Run task" })
```

❌ **Wrong:**
```lua
vim.keymap.set("n", "<leader>t", function()
  vim.cmd("!npm run test:unit -- --coverage")
end, { desc = "Run tests" })
```

The first invokes the repository's interface. The second hides project knowledge in dotfiles.

**Rule:** Neovim invokes the repository. The repository doesn't know about Neovim.

## Command Vocabulary

Use these same command names across all your projects. Your muscle memory will carry across codebases:

```
just              List all available commands
just help         Show command help
just doctor       Validate environment
just setup        First-time setup
just run          Run the app
just dev          Run in development mode
just debug        Debug instructions
just test         Full test suite
just test-one X   Run one test matching X
just lint         Linting
just format       Apply formatting
just format-check Check formatting
just check        Fast checks (lint, format, test)
just build        Compile/bundle
just clean        Remove generated output
just ci           Local CI simulation
```

## Example: Node.js Project

**justfile:**
```bash
set dotenv-load := true

default:
    @just --list

doctor:
    @echo "Checking Node.js environment..."
    @mise doctor
    node --version
    npm --version
    @test -f .env || { echo "Missing .env"; exit 1; }

setup:
    mise install
    npm ci
    npm run build

run:
    npm start

dev:
    npm run dev

debug:
    @echo "Set breakpoints in the code."
    @echo "Run: F5 in Neovim (or use your debugger)."
    @echo "Debug configs: .vscode/launch.json"

test:
    npm run test

test-one filter:
    npm run test -- --testNamePattern="{{filter}}"

check:
    just format-check
    just lint
    just test

format:
    npx prettier --write .

format-check:
    npx prettier --check .

lint:
    npx eslint .

build:
    npm run build

clean:
    rm -rf dist coverage node_modules/.cache

ci:
    just check
    just build
```

**mise.toml:**
```toml
[tools]
node = "22"
npm = "10"
just = "latest"

[env]
NODE_ENV = "development"
_.file = ".env"
```

**README.md:**
```markdown
# My App

A Node.js application for [purpose].

## Quick Start

```bash
mise install
cp .env.example .env
just setup
just dev
```

## Commands

```bash
just run       # Start the server
just test      # Run tests
just lint      # Check code style
```

For debugging, see `.vscode/launch.json`.

For details, see `docs/development.md`.
```

## When NOT to Use This Pattern

- **Disposable scripts:** One-off data migrations or scripts don't need a full justfile
- **Library-only projects:** If you have no CLI entry point or tests, skip some recipes
- **Very simple projects:** A single Python script may not need `mise.toml` or `docs/development.md`

In those cases, keep the README and justfile (or scripts/) but omit unnecessary ceremony.

## Evolution

Once the foundation is solid, you can layer quality-of-life improvements:

- A Neovim picker over `just --list` (via Snacks or fzf-lua)
- A project template generator
- A Neovim command that opens a terminal and runs a task
- Pre-commit hooks that enforce required recipes exist

But these are optional. The durable base is the committed files.

## Summary

This pattern is more career-proof than:
- Shell history (doesn't survive context loss)
- Obsidian/Notion (doesn't travel with branches, teammates can't access)
- Personal dotfiles (locks knowledge in your editor config)
- Slack threads (information rots)

It's less overhead than:
- Docker Compose for every single project
- CI/CD-only workflows (can't work locally)
- Large custom TUI launchers

Start here. Keep it simple. Build muscle memory around the same command names. When you switch projects, you'll know exactly what to run.
