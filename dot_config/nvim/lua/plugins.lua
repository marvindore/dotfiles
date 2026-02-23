-- plugin manager hub
-- 1. The Build System Hook
local augroup = vim.api.nvim_create_augroup('native_build_system', { clear = false })
vim.api.nvim_create_autocmd("PackChanged", {
	group = augroup,
	pattern = "*",
	callback = function(e)
		local p = e.data
		local run_task = (p.spec.data or {}).run
		if p.kind ~= "delete" and type(run_task) == 'function' then
			pcall(run_task, p)
		end
	end,
})

-- 2. Bootstrap `lze`
vim.pack.add({ "https://github.com/BirdeeHub/lze" })

-- 3. Load your individual plugin files
require("plugins.colorscheme")
require("plugins.treesitter")
require("plugins.treesitter-context")
require("plugins.mini")
require("plugins.aerial")
require("plugins.auto-session")
require("plugins.blink")
require("plugins.codediff")
require("plugins.companion")
require("plugins.conform")
require("plugins.dap")
require("plugins.dapview")
require("plugins.easydotnet")
require("plugins.flash")
require("plugins.fzf-lua")
require("plugins.snacks")
require("plugins.gitsigns")
require("plugins.hlslens")
require("plugins.iron")
require("plugins.lazydev")
require("plugins.lint")
require("plugins.lualine")
require("plugins.multi_cursors")
require("plugins.neotest")
require("plugins.opencode")
require("plugins.render_markdown")
require("plugins.whichkey")
--require("plugins.zellij")
require("plugins.lsp_csharp")
require("plugins.lsp_java")
require("plugins.lsp_javascript")
require("plugins.lsp_mason")
require("plugins.lsp_rustacean")
