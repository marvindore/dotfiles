vim.pack.add({ { src = "https://github.com/echasnovski/mini.nvim" } })

-- Configurations
-- Treesitter text objects (queries from nvim-treesitter-textobjects): F = function, c = class.
-- mini.ai defaults keep f = function call, a = argument.
local ai = require("mini.ai")
ai.setup({
	custom_textobjects = {
		F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
		c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
	},
})

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
