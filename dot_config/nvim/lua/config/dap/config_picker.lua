-- DAP configuration picker grouped by config provider (see :h dap-providers-configs).
-- Groups are derived from the provider that returned a config; no name lists or markers.

local M = {}

local PROVIDER_ID = "local-launch"

-- Display order and labels per provider key
local GROUPS = {
  { provider = "dap.global", label = "Neovim" },
  { provider = "dap.launch.json", label = "Project" },
  { provider = PROVIDER_ID, label = "Local" },
}

--- Per-project configs that stay out of the repo: <cwd>/.nvim/launch.json (same format as .vscode/launch.json)
local function register_local_provider()
  local dap = require("dap")
  if dap.providers.configs[PROVIDER_ID] then
    return
  end
  dap.providers.configs[PROVIDER_ID] = function()
    local path = vim.fn.getcwd() .. "/.nvim/launch.json"
    local ok, configs = pcall(require("dap.ext.vscode").getconfigs, path)
    if not ok then
      vim.notify_once("Can't read " .. path .. ":\n" .. tostring(configs), vim.log.levels.WARN, { title = "DAP" })
      return {}
    end
    return configs
  end
end

local function group_label(provider)
  for _, group in ipairs(GROUPS) do
    if group.provider == provider then
      return group.label
    end
  end
  return provider
end

--- Provider keys in display order: known groups first, then any plugin-provided ones
local function ordered_providers(dap)
  local keys, seen = {}, {}
  for _, group in ipairs(GROUPS) do
    table.insert(keys, group.provider)
    seen[group.provider] = true
  end
  local extra = {}
  for key in pairs(dap.providers.configs) do
    if not seen[key] then
      table.insert(extra, key)
    end
  end
  table.sort(extra)
  return vim.list_extend(keys, extra)
end

local function collect_items(dap, bufnr)
  local items = {}
  for _, provider in ipairs(ordered_providers(dap)) do
    local fn = dap.providers.configs[provider]
    local ok, configs = pcall(fn, bufnr)
    if ok and type(configs) == "table" then
      for _, config in ipairs(configs) do
        table.insert(items, { config = config, group = group_label(provider) })
      end
    end
  end
  return items
end

--- Show configs from all providers, grouped, and run the selected one
function M.pick_configuration()
  local dap = require("dap")
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype

  -- Providers are called inside a coroutine, as nvim-dap does
  coroutine.wrap(function()
    local items = collect_items(dap, bufnr)
    if #items == 0 then
      vim.notify("No DAP configurations found for filetype: " .. filetype, vim.log.levels.WARN)
      return
    end
    vim.ui.select(items, {
      prompt = "Select Debug Configuration:",
      format_item = function(item)
        return string.format("[%s] %s", item.group, item.config.name)
      end,
    }, function(choice)
      if choice then
        dap.run(choice.config, { filetype = filetype })
      end
    end)
  end)()
end

--- Continue a running session, otherwise pick a configuration
function M.continue()
  local dap = require("dap")
  if dap.session() then
    dap.continue()
    return
  end
  M.pick_configuration()
end

function M.setup()
  register_local_provider()
end

return M
