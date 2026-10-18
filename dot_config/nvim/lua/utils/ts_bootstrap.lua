-- Install missing tree-sitter parsers (nvim-treesitter main API).
-- Used at startup (async), by :TSBootstrap, and by the chezmoi headless
-- bootstrap script, which waits on the returned task.
local M = {}

local function has_parser(lang)
  local so   = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so",   false)
  local wasm = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".wasm", false)
  return #so > 0 or #wasm > 0
end

---@return string[] languages from utils.ts_langs that have no installed parser
function M.missing()
  return vim.tbl_filter(function(lang) return not has_parser(lang) end, require("utils.ts_langs"))
end

--- Start installing the missing parsers.
---@return table? task nvim-treesitter task (call `:wait(ms)` to block); nil when nothing is missing
function M.install_missing()
  local missing = M.missing()
  if #missing == 0 then return nil end
  return require("nvim-treesitter").install(missing)
end

return M
