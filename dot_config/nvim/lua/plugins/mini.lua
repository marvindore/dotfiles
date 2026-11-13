vim.pack.add({ { src = "https://github.com/echasnovski/mini.nvim" } })

-- Configurations
require("mini.ai").setup()

require("mini.comment").setup()

require("mini.surround").setup({
	mappings = {
		add = "sa",
		delete = "sd",
		find = "sf",
		find_left = "sF",
		highlight = "sh",
		replace = "sr",
		update_n_lines = "sn",
	},
})

require("mini.pairs").setup()
require("mini.indentscope").setup()

require("mini.move").setup({
	mappings = {
		left = "<C-S-left>",
		right = "<C-S-right>",
		down = "<C-S-down>",
		up = "<C-S-up>",
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


-- Keymaps
vim.keymap.set("n", "saw","saiw", { remap = true, desc = "Surround word" })
