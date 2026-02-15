-- 1. Add Blink and dependencies (Removed blink-cmp-avante)
vim.pack.add({
	"https://github.com/rafamadriz/friendly-snippets",
	{
		src = "https://github.com/saghen/blink.cmp",
		data = {
			run = function(p)
				vim.notify("Pinning blink.cmp to v1.9.1...", vim.log.levels.INFO)
				vim.system({ "git", "checkout", "tags/v1.9.1" }, { cwd = p.spec.path }):wait()
			end,
		},
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
		prebuilt_binaries = {
			download = true,
			force_version = "v1.9.1",
		},
	},
})
