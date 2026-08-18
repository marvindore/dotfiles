# .vscode/launch.json Template for Neovim DAP

Industry-standard DAP configurations for debugging. Place `.vscode/launch.json` in your project root — it's read natively by DAP clients, including Neovim's nvim-dap.

## Architecture Pattern

**Single workflow for Neovim:**

1. **Terminal**: Start your app with debug flags (e.g., `just debug` or equivalent)
2. **Neovim DAP**: Press `F5` to open config picker → select "Attach" config → DAP connects to running process

This attach-based pattern decouples process lifecycle from the debugger, making it robust for:
- Long-running services
- Multiple debugging sessions
- Interactive development (restart app without restarting debugger)

- ✅ `launch.json` contains **Attach configs only** (DAP connects to running process)
- ✅ `justfile` recipes handle **process lifecycle** (start with debug flags)

## Python

**launch.json:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Attach to localhost:5678",
      "type": "python",
      "request": "attach",
      "port": 5678,
      "host": "localhost",
      "justMyCode": false
    }
  ]
}
```

**Neovim workflow:**
1. Terminal: `just debug` (starts debugpy listener on port 5678)
2. Neovim: `F5` → select "Python: Attach to localhost:5678" → DAP connects

**justfile:**
```bash
debug *args:
    python -m debugpy --listen 5678 src/main.py {{args}}
```

---

## TypeScript / Node.js

**launch.json:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Node: Attach to localhost:9229",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

**Neovim workflow:**
1. Terminal: `just debug` (Node starts with debug port 9229)
2. Neovim: `F5` → select "Node: Attach to localhost:9229" → DAP connects

**justfile:**
```bash
debug *args:
    node --inspect=9229 dist/index.js {{args}}
```

---

## Rust (LLDB)

**launch.json:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Rust: Attach by PID",
      "type": "lldb",
      "request": "attach",
      "pid": "${command:pickProcess}"
    }
  ]
}
```

**Neovim workflow:**
1. Terminal: `just debug` (build and run)
2. Neovim: `F5` → select "Rust: Attach by PID" → choose process from picker

**justfile:**
```bash
debug *args:
    cargo run {{args}}
```

---

## C# / .NET

**launch.json:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": ".NET: Attach by PID",
      "type": "coreclr",
      "request": "attach",
      "processId": "${command:pickProcess}"
    }
  ]
}
```

**Neovim workflow:**
1. Terminal: `just run` (start Pay.Api or your .NET app)
2. Neovim: `F5` → select ".NET: Attach by PID" → choose dotnet process from picker

**justfile:**
```bash
debug *args:
    dotnet run --project Pay.Api/Pay.Api.csproj {{args}}

run *args:
    dotnet run --project Pay.Api/Pay.Api.csproj {{args}}
```

---

## Go (Delve)

**launch.json:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Go: Attach to localhost:38697",
      "type": "go",
      "request": "attach",
      "mode": "local",
      "port": 38697,
      "host": "localhost",
      "logOutput": "rpc"
    }
  ]
}
```

**Neovim workflow:**
1. Terminal: `just debug` (dlv starts headless listener)
2. Neovim: `F5` → select "Go: Attach to localhost:38697" → DAP connects

**justfile:**
```bash
debug *args:
    dlv debug --headless --listen=:38697 --api-version=2 ./cmd/main.go {{args}}
```

---

## Neovim DAP Usage

1. Place `.vscode/launch.json` in your project root
2. In Neovim: Toggle breakpoints with `<leader>db`
3. Press `F5` to open DAP config picker
4. Select "Attach ..." config
5. Debugger attaches to running process and pauses at breakpoints

**Standard Keybindings (nvim-dap):**
- `F5` — continue / start debugging (or select config if picker open)
- `F6` — pause
- `F9` — toggle breakpoint at cursor
- `F10` — step over
- `F11` — step into
- `Shift+F11` — step out
- `:DapUiToggle` — open debug sidebar
- `:DapSetLogLevel TRACE` — verbose logging (troubleshooting)

**Process:**
- Always start your app in a terminal first: `just debug` (or your equivalent)
- Then attach from Neovim via `F5` config picker
- Restarting app in terminal does NOT disconnect debugger (it will reconnect when process restarts)
