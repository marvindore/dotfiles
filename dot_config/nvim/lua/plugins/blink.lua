-- 1. Add Blink and dependencies
-- blink.cmp `main` is v2 pre-release and needs saghen/blink.lib. Stay on the
-- last 1.x release until v2 is tagged. vim.pack resolves the range to the
-- newest 1.x tag on install and on :PackUpdate.
vim.pack.add({
	"https://github.com/rafamadriz/friendly-snippets",
	{
		src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("1.*"),
	},
})

-- 2. Setup blink.cmp eagerly
require("blink.cmp").setup({
	keymap = { preset = "super-tab" },

	appearance = {
		nerd_font_variant = "mono",
	},

	completion = {
		documentation = { auto_show = true },
		menu = {
			draw = {
				columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
			},
		},
	},

	signature = { enabled = true },

	-- 3. CRITICAL FIX: Removed the buggy 'avante' source from the defaults
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},

	fuzzy = {
		-- Version is detected from the checked-out tag; no force_version needed.
		prebuilt_binaries = {
			download = true,
		},
	},
})
