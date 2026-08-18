# Neovim DAP Grouped Picker Pattern

Distinguish between hardcoded Neovim configs and project-specific `.vscode/launch.json` configs in the F5 picker UI.

## Why?

Neovim users configure DAP in Lua (editor-native). Projects also commit `.vscode/launch.json` (cross-editor standard). Without grouping, the F5 picker is confusing — users don't know which configs are permanent vs project-specific.

**Solution:** Group picker by source with clear headers.

---

## Architecture Pattern

**Two complementary approaches coexist:**

1. **Hardcoded Neovim configs** (in dap.lua)
   - Permanent, part of your editor setup
   - Persist across projects
   - Examples: "Launch FastAPI", "CoreCLR: Build & Launch", "rustacean"

2. **Project-specific configs** (in `.vscode/launch.json`)
   - Versioned with the project
   - Team-shared
   - Auto-loaded by nvim-dap
   - Examples: "Python: Launch src/main.py", "Python: Attach to localhost:5678"

**Both are valid.** The grouped picker makes this distinction explicit.

---

## Implementation

### Step 1: Create the grouped picker module

Save to `~/.local/share/chezmoi/dot_config/nvim/lua/dap_grouped_picker.lua`:

```lua
-- DAP Configuration picker with grouped headers
-- Distinguishes between Neovim-hardcoded configs and Project-loaded configs

local M = {}

-- Categorize configs: Neovim (hardcoded) vs Project (.vscode/launch.json)
local function categorize_dap_configs(configs)
  -- Hardcoded Neovim configs (defined in your dap.lua)
  local hardcoded_names = {
    "Launch FastAPI",
    "CoreCLR: Build & Launch",
    "rustacean",
    "Go: Launch (debug)",
    "Debug Neovim-kind",
    "Python: Launch",
    "Python: Debug Tests",
    -- Add your custom hardcoded configs here
  }

  local hardcoded = {}
  local project = {}

  for _, config in ipairs(configs) do
    local is_hardcoded = false

    -- Check if this config name is in the hardcoded list
    for _, hardcoded_name in ipairs(hardcoded_names) do
      if config.name == hardcoded_name then
        is_hardcoded = true
        break
      end
    end

    if is_hardcoded then
      table.insert(hardcoded, config)
    else
      table.insert(project, config)
    end
  end

  return {
    neovim = hardcoded,
    project = project,
  }
end

-- Format configs with group headers
local function format_grouped_configs(configs)
  local categories = categorize_dap_configs(configs)
  local formatted = {}

  -- Add Neovim section
  if #categories.neovim > 0 then
    table.insert(formatted, {
      text = "─── Neovim ───",
      name = "─── Neovim ───",
      is_header = true,
      disabled = true,
    })

    for _, config in ipairs(categories.neovim) do
      table.insert(formatted, {
        text = config.name,
        name = config.name,
        config = config,
        is_config = true,
        group = "neovim",
      })
    end
  end

  -- Add Project section
  if #categories.project > 0 then
    table.insert(formatted, {
      text = "─── Project ───",
      name = "─── Project ───",
      is_header = true,
      disabled = true,
    })

    for _, config in ipairs(categories.project) do
      table.insert(formatted, {
        text = config.name,
        name = config.name,
        config = config,
        is_config = true,
        group = "project",
      })
    end
  end

  return formatted
end

-- Main picker function
function M.pick_configuration()
  local dap = require('dap')
  local ft = vim.bo.filetype
  local configs = dap.configurations[ft] or {}

  if #configs == 0 then
    vim.notify("No DAP configurations for filetype: " .. ft, vim.log.levels.WARN)
    return
  end

  local formatted = format_grouped_configs(configs)

  vim.ui.select(formatted, {
    prompt = "Select Debug Configuration:",
    format_item = function(item)
      if item.is_header then
        return item.name
      else
        -- Indent config entries slightly
        return "  " .. item.name
      end
    end,
  }, function(choice)
    if not choice or not choice.is_config then
      return
    end

    -- Launch DAP with selected config
    dap.run(choice.config)
  end)
end

return M
```

### Step 2: Update F5 keybinding

In your `dap.lua` plugin file, change the F5 keybinding:

**Before:**
```lua
{ lhs = "<F5>", rhs = ":lua require('dap').continue()<CR>", mode = "n", desc = "Debug continue" },
```

**After:**
```lua
{ lhs = "<F5>", rhs = ":lua require('dap_grouped_picker').pick_configuration()<CR>", mode = "n", desc = "Debug continue/select config" },
```

### Step 3: Commit .vscode/launch.json to your project

See `launch-json-template.md` for templates for each language.

---

## Customization

### Add new hardcoded configs

Edit `hardcoded_names` in `dap_grouped_picker.lua`:

```lua
local hardcoded_names = {
  "Launch FastAPI",
  "My Custom Config",  -- Add here
}
```

### Change group headers

Edit the header strings:

```lua
table.insert(formatted, {
  text = "┌─ Neovim ─────────┐",  -- Change this
  name = "┌─ Neovim ─────────┐",
  ...
})
```

### Adjust formatting

Modify the `format_item` function in `pick_configuration()`:

```lua
format_item = function(item)
  if item.is_header then
    return "═══ " .. item.name .. " ═══"  -- Custom header styling
  else
    return "  " .. item.name
  end
end,
```

---

## Why This Pattern?

**Resolves the "where should DAP config live?" question:**

| Approach | Pros | Cons |
|----------|------|------|
| **Only .vscode/launch.json** | Team-shared, portable | Neovim users need manual wiring |
| **Only hardcoded Lua** | Neovim-idiomatic, auto-loads | Not portable, scattered across dotfiles |
| **Grouped picker (both)** | ✅ Both work, clearly distinguished | ✅ No confusion about config sources |

**Professional result:**
- IDE-specific configs (hardcoded Lua) stay in your editor setup
- Project configs (`.vscode/launch.json`) stay versioned with the code
- Both serve their purpose; both are discoverable; no duplicated knowledge

---

## References

- Neovim DAP documentation: `:help dap-configuration`
- nvim-dap GitHub: https://github.com/mfussenegger/nvim-dap
- `.vscode/launch.json` templates: See `launch-json-template.md`
