vim.pack.add({ { src = "https://github.com/echasnovski/mini.nvim" } })

-- Configurations
require("mini.ai").setup()

-- local diff = require("mini.diff")
-- diff.setup({ source = diff.gen_source.none() })

require("mini.diff").setup({
  view = {
    -- Visualization style. Possible values are 'sign' and 'number'.
    -- Default: 'number' if line numbers are enabled, 'sign' otherwise.
    style = 'sign',

    -- Signs used for hunks with 'sign' view
    signs = { add    = '▏', change = '▏', delete = '▏',},

    -- Priority of used visualization extmarks
    priority = 199,
  },
  mappings = {
    goto_first = '[C',
    goto_prev = '[c',
    goto_next = ']c',
    goto_last = ']C',
  }
})
require("mini.files").setup({ mappings = { go_in_plus = "<cr>" } })
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


-- Keymaps
vim.keymap.set("n", "-", ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>", { desc = "Open directory" })
vim.keymap.set("n", "_", ":lua MiniFiles.open()<cr>", { desc = "Open parent directory" })
vim.keymap.set("n", "<leader>gd", function() require("mini.diff").toggle_overlay(0) end, { desc = "Git buffer diff" })
vim.keymap.set("n", "saw", "saiw", { remap = true, desc = "Surround word" })

