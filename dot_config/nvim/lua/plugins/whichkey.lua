-- 1. Add the plugin to the package path immediately
vim.pack.add({ "https://github.com/folke/which-key.nvim" })

local wk = require("which-key")

-- 2. Run the setup
wk.setup({
	-- Your specific which-key options go here
})

-- 3. This makes sure that as soon as you open Neovim,
-- these labels are ready for keymappings.lua to use.
wk.add({
	{ "<leader>f", group = "file/find" },
	{ "<leader>g", group = "git" },
	{ "<leader>d", group = "debug" },
	{ "<leader>r", group = "repl/iron" },
	{ "<leader>t", group = "test" },
	{
		"<leader>?",
		function()
			wk.show({ global = false })
		end,
		desc = "Buffer Local Keymaps",
	},
})
