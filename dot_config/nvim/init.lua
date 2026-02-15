vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("globals")
require("settings")
require("plugins")
require("utils.packhealth")

require("keymappings")
vim.api.nvim_set_hl(0, 'BugIcon', { fg = '#FF0000' })

vim.api.nvim_create_autocmd("SessionLoadPost", {
    callback = function() require("utils.dap_breakpoints").load_breakpoints() end,
})


-- >>> LSP module: register autocmds, global capabilities, and enable servers
local lsp_setup = require("lsp_setup")
lsp_setup.setup_lsp_attach()
lsp_setup.setup_global_capabilities()
lsp_setup.enable_servers({
  -- Pass explicit session flags here if you want, otherwise it uses vim.g.* toggles.
  -- enable_js   = true,
  -- enable_sql  = false,
  -- enable_go   = true,
  -- enable_pwsh = (vim.fn.has("win32") == 1),
  -- enable_cs   = true,
  -- enable_rust = true,
})
-- <<< End LSP module
