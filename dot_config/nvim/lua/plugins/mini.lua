vim.pack.add({ "https://github.com/echasnovski/mini.nvim" })

-- Keymaps
vim.keymap.set("n", "-", ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>", { desc = "Open directory" })
vim.keymap.set("n", "_", ":lua MiniFiles.open()<cr>", { desc = "Open parent directory" })
vim.keymap.set("x", "yy", "y", { desc = "Yank Selection" })

-- Configurations
require("mini.ai").setup()

local diff = require("mini.diff")
diff.setup({ source = diff.gen_source.none() })

require("mini.files").setup({ mappings = { go_in_plus = "<cr>" } })
require("mini.comment").setup()
require("mini.bracketed").setup()

require("mini.surround").setup({
	mappings = {
		add = "ysa",
		delete = "ysd",
		find = "ysf",
		find_left = "ysF",
		highlight = "ysh",
		replace = "ysr",
		update_n_lines = "ysn",
	},
})

require("mini.pairs").setup()
require("mini.indentscope").setup()

require("mini.move").setup({
	mappings = {
		left = "<S-left>",
		right = "<S-right>",
		down = "<S-down>",
		up = "<S-up>",
		line_left = "",
		line_right = "",
		line_down = "",
		line_up = "",
	},
})

require("mini.splitjoin").setup()

local hipatterns = require("mini.hipatterns")
hipatterns.setup({
	highlighters = {
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		hex_color = hipatterns.gen_highlighter.hex_color(),
	},
})
