-- plugin manager hub
-- 1. The Build System Hook
-- `data.run`:   function(p) called after install and update. `p.path` is the plugin dir.
-- `data.build`: Ex command string run after an update (e.g. ":TSUpdate"). On install the
--               plugin is not loaded yet, so the command would not exist.
local function run_build_hooks(p)
	local data = p.spec.data or {}
	if type(data.run) == "function" then pcall(data.run, p) end
	if p.kind == "update" and type(data.build) == "string" then pcall(vim.cmd, data.build) end
end

local augroup = vim.api.nvim_create_augroup('native_build_system', { clear = false })
vim.api.nvim_create_autocmd("PackChanged", {
	group = augroup,
	pattern = "*",
	callback = function(e)
		if e.data.kind ~= "delete" then run_build_hooks(e.data) end
	end,
})

-- 2. Bootstrap `lze`
vim.pack.add({ "https://github.com/BirdeeHub/lze" })

-- 3. Load your individual plugin files
require("plugins.colorscheme")
require("plugins.treesitter")
require("plugins.treesitter-context")
require("plugins.mini")
require("plugins.yazi")
require("plugins.aerial")
require("plugins.auto-session")
require("plugins.blink")
require("plugins.diffview")
--require("plugins.companion")
if vim.g.enableCopilot then require("plugins.copilot") end
if vim.g.enableCopilot then require("plugins.copilot-chat") end
require("plugins.conform")
require("plugins.dap")
require("plugins.dapview")
require("plugins.easydotnet")
require("plugins.flash")
require("plugins.fzf-lua")
require("plugins.img-clip")
require("plugins.snacks")
--require("plugins.gitsigns")
require("plugins.hlslens")
require("plugins.iron")
require("plugins.lazydev")
require("plugins.lint")
require("plugins.lualine")
require("plugins.neotest")
require("plugins.opencode")
require("plugins.overseer")
require("plugins.render_markdown")
require("plugins.whichkey")
require("plugins.roslyn")
require("plugins.jdtls")
require("plugins.vtsls")
require("plugins.mason")
require("plugins.rustacean")
require("plugins.smart-splits")
--require("plugins.mkdnflow")
require("plugins.zk")
