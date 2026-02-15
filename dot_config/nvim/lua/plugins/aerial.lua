vim.pack.add({
	{
		src = "https://github.com/stevearc/aerial.nvim",
		data = {
			-- lze will automatically create the dummy command and load the plugin when typed!
			cmd = { "AerialToggle" },
			keys = {
				{ lhs = "<LocalLeader>ss", rhs = "<cmd>AerialToggle!<cr>", mode = "n", desc = "Symbols outline" },
				{ lhs = "<LocalLeader>{", rhs = "<cmd>AerialPrev!<cr>", mode = "n", desc = "Symbols outline" },
				{ lhs = "<LocalLeader>}", rhs ="<cmd>AerialNext!<cr>", mode = "n", desc = "Symbols outline" },
				{ lhs = "<LocalLeader>sf", rhs = "<cmd>call aerial#fzf()<cr>", mode = "n", desc = "Symbols Fzf" },
			},
			after = function(_)
				require("aerial").setup({})
			end,
		},
	},
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/nvim-tree/nvim-web-devicons",
}, {
	-- This tells vim.pack to hand the `data` table over to `lze` for lazy-loading
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
