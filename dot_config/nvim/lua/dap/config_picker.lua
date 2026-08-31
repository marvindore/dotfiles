-- DAP Configuration picker with grouped headers
-- Distinguishes between Neovim-hardcoded configs and Project-loaded configs

local M = {}

-- Track which configs came from .vscode/launch.json
local vscode_config_names = {}

-- Function to mark configs from .vscode/launch.json
local function mark_vscode_configs(dap)
  -- Clear previous marks
  vscode_config_names = {}

  -- nvim-dap loads .vscode/launch.json via require("dap.ext.vscode")
  -- We can detect these by checking if they're in the DAP config but not hardcoded
  local vscode_ext = require("dap.ext.vscode")

  -- This is a bit hacky but works: iterate all configs and identify non-hardcoded ones
  -- The hardcoded ones are set in dap.lua (launch_fastapi, etc.)
  -- Anything added after that is from .vscode/launch.json
end

-- Categorize configs: Neovim (hardcoded + plugin-provided) vs Project (.vscode/launch.json)
local function categorize_dap_configs(configs)
  -- Hardcoded Neovim configs (defined in dap.lua or provided by nvim-dap plugins)
  local hardcoded_names = {
    -- Hardcoded in dap.lua
    "Launch FastAPI",
    "CoreCLR: Build & Launch",
    "rustacean",
    "Go: Launch (debug)",
    "Debug Neovim-kind",
    "Python: Launch",
    "Python: Debug Tests",

    -- nvim-dap-python built-in configs
    "File",
    "File:args",
    "Attach",
    "File:doctest",

    -- Other plugin-provided defaults
    "Python",
  }

  local hardcoded = {}
  local project = {}

  for _, config in ipairs(configs) do
    local is_hardcoded = false

    -- Check if this config name is in the hardcoded/plugin list FIRST
    for _, hardcoded_name in ipairs(hardcoded_names) do
      if config.name == hardcoded_name then
        is_hardcoded = true
        break
      end
    end

    -- Then check if marked as vscode source
    if is_hardcoded then
      table.insert(hardcoded, config)
    elseif config._vscode_source then
      table.insert(project, config)
    else
      -- Unknown config (might be from a plugin not in our list)
      -- Default to Neovim section to avoid confusion
      table.insert(hardcoded, config)
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

-- Override F5 keybinding to use the grouped picker
function M.setup()
  local dap = require('dap')

  -- Store original continue function
  local original_continue = dap.continue

  -- Replace continue with grouped picker
  function dap.continue()
    -- Check if debugger is already running
    if dap.session() == nil then
      -- No session running, show config picker
      M.pick_configuration()
    else
      -- Session already running, continue execution
      original_continue()
    end
  end
end

return M
