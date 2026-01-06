local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("globals")
require("settings")

require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	rocks = {
		enabled = true,
	},
})

require("keymappings")
vim.api.nvim_set_hl(0, 'BugIcon', { fg = '#FF0000' })

vim.api.nvim_create_autocmd("SessionLoadPost", {
    callback = function() require("lib.dap").load_breakpoints() end,
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
