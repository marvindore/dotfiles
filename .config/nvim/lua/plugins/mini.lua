return {
	{
		"echasnovski/mini.nvim",
		version = false,
		config = function()
			require("mini.ai").setup()
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
			    update_n_lines = "Sn"
			  }
			})
			require("mini.pairs").setup()
			require("mini.indentscope").setup()
			require("mini.move").setup()
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
