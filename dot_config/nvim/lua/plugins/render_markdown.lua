vim.pack.add({
	-- 1. Dependencies
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/echasnovski/mini.nvim",

	-- 2. The Main Plugin
	{
		src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
		data = {
			-- Lazy load on markdown and AI-related filetypes
			ft = { "markdown", "codecompanion", "opencode" },

			after = function(_)
				require("render-markdown").setup({
					-- Enables rendering in Normal, Command, and Terminal modes
					render_modes = { "n", "c", "t" },

					-- Integrated with your existing theme
					anti_conceal = {
						enabled = true,
					},
					preset = "obsidian", -- Optional: makes it look a bit more like a modern editor
				})
			end,
		},
	},
}, {
	-- Standard lze loading hook
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
