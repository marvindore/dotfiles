vim.pack.add({
	{
		src = "https://github.com/MagicDuck/grug-far.nvim",
		data = {
			keys = {
				{ lhs = "<leader>sr", rhs = ":GrugFar<cr>", mode = "n", desc = "Grug Far (bulk replace)" },
			},
			after = function(_)
				require("grug-far").setup({
					transient = false,
					staticTitle = "Find and Replace",
					keymaps = {
						abort = { n = "<C-c>", v = "<C-c>" },
						openNextMatch = { n = "<enter>" },
						openPrevMatch = { n = "<S-enter>" },
						gotoMatch = { n = "o", v = "o" },
						pickHistoryPrev = { n = "<C-p>" },
						pickHistoryNext = { n = "<C-n>" },
						syncLocations = { n = "s" },
						toggleShowCommand = { n = "?" },
						swapEngine = { n = "<C-e>" },
						previewFullLine = { n = "P" },
						openLocation = { n = "<C-o>" },
						openLocationNewTab = { n = "<C-t>" },
					},
				})
			end,
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
