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
    -- Disabled here and re-implemented below as global keymaps that fall
    -- back to Vim's built-in diff-mode ]c/[c when inside a 'diff' window
    -- (e.g. diffview.nvim). mini.diff maps these globally, not buffer-local,
    -- so without the fallback they permanently shadow diffview's own hunk
    -- navigation and report "No hunks to go to" (mini's git-diff source has
    -- no relation to whatever revisions diffview is comparing).
    goto_first = '',
    goto_prev = '',
    goto_next = '',
    goto_last = '',
  },
  options = {
    algorithm = 'patience',
    indent_heuristic = true,
    linematch = 60, -- 👈 enables better intra-line diffing
  },
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
vim.keymap.set("n", "-", ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>", { desc = "Open directory" })
vim.keymap.set("n", "_", ":lua MiniFiles.open()<cr>", { desc = "Open parent directory" })

vim.keymap.set("n", "<leader>gd", function()
  require("mini.diff").toggle_overlay(0)
end, { desc = "Toggle inline diff popup" })

vim.keymap.set("n", "<leader>gh", function()
  require("mini.diff").goto_hunk("current")
end, { desc = "Focus current diff hunk" })

-- Hunk navigation: defer to Vim's built-in diff-mode ]c/[c inside 'diff'
-- windows (diffview.nvim, :diffthis, etc.); use mini.diff everywhere else.
local function goto_hunk_or_diff(mini_direction, builtin_key)
  return function()
    if vim.wo.diff then
      vim.cmd("normal! " .. builtin_key)
    else
      require("mini.diff").goto_hunk(mini_direction)
    end
  end
end

vim.keymap.set({ "n", "x" }, "[c", goto_hunk_or_diff("prev", "[c"), { desc = "Previous hunk / diff change" })
vim.keymap.set({ "n", "x" }, "]c", goto_hunk_or_diff("next", "]c"), { desc = "Next hunk / diff change" })
vim.keymap.set({ "n", "x" }, "[C", goto_hunk_or_diff("first", "[c"), { desc = "First hunk / diff change" })
vim.keymap.set({ "n", "x" }, "]C", goto_hunk_or_diff("last", "]c"), { desc = "Last hunk / diff change" })

vim.keymap.set("n", "saw", "saiw", { remap = true, desc = "Surround word" })
