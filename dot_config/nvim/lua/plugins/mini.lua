return {
	{
		"echasnovski/mini.nvim",
		version = false,
		config = function()
			require("mini.ai").setup()
			local diff = require("mini.diff")
			diff.setup({
				source = diff.gen_source.none(),
			})

			require("mini.files").setup({
				mappings = {
					go_in_plus = "<cr>",
				},
			})
			require("mini.comment").setup()
			require("mini.bracketed").setup()
			require("mini.surround").setup({
				mappings = {
					add = "Sa",
					delete = "Sd",
					find = "Sf",
					find_left = "SF",
					highlight = "Sh",
					replace = "Sr",
					update_n_lines = "Sn",
				},
			})
			require("mini.pairs").setup()
			require("mini.indentscope").setup()
			require("mini.move").setup({
				mappings = {
					-- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
					left = "<S-left>",
					right = "<S-right>",
					down = "<S-down>",
					up = "<S-up>",

					-- Move current line in Normal mode
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
					-- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
					fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
					hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
					todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
					note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

					-- Highlight hex color strings (`#rrggbb`) using that color
					hex_color = hipatterns.gen_highlighter.hex_color(),
				},
			})
		end,
	},
}
