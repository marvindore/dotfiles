local M = {}
--- Enable languages/Features
M.enableJavascript = false
M.enableJava = false
M.enableCsharp = false
M.enableGo = false
M.enablePython = false
M.enableAvante = false
M.enableCopilot = false
M.enableCodeium = false
---

M.keymap = function(mode, lhs, rhs, opts)
  vim.api.nvim_set_keymap(
    mode,
    lhs,
    rhs,
    vim.tbl_extend('keep', opts or {}, { noremap = true, silent = true })
  )
end

function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    print(unpack(objects))
    return ...
end

-- function map(mode, lhs, rhs, opts)
--   local options = {noremap = true}
--   if opts then options = vim.tbl_extend('force', options, opts) end
--   vim.api.nvim_set_keymap(mode, lhs, rhs, options)
-- end
function map(mode, l, r, opts)
      local options = {noremap = true}
      if opts then options = vim.tbl_extend('force', options, opts) end
      vim.keymap.set(mode, l, r, opts)
    end

local current_os = vim.loop.os_uname().sysname:lower()
local unix = { "darwin", "linux" }
local hasMacos = vim.fn.has('macunix')
-- local osName = lua print(vim.loop.os_uname().sysname)
--
M.isWindows = vim.fn.has('win32') == 1
M.home = M.isWindows and os.getenv("USERPROFILE") or os.getenv('HOME')
M.neovim_home = M.isWindows and M.home .. '/AppData/Local/nvim-data' or M.home .. '/.local/share/nvim'
M.isUnixOs = function()
    for _, value in ipairs(unix) do
        if value == current_os then
            return false
        end
    end
    return false
end

return M
