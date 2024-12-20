local M = {}

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

function map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- nvim-dap
-- function attach()
--   print('attaching')
--   dap.run({
--       type = 'node2',
--       request = 'attach',
--       cwd = vim.fn.getcwd(),
--       sourceMaps = true,
--       protocol = 'inspector',
--       skipFiles = {'<node_internals>/**/*.js'},
--       })
-- end

-- local function lsp_keymaps(bufnr)
--   local opts = { noremap = true, silent = true }
--   vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
-- end

-- M.on_attach = function(client, bufnr)
--   if client.name == "tsserver" then
--     client.resolved_capabilities.document_formatting = false
--   end
--   lsp_keymaps(bufnr)
-- end

local current_os = vim.loop.os_uname().sysname:lower()
local unix = { "darwin", "linux" }
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
