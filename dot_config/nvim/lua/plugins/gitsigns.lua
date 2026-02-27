vim.pack.add({
	{
		src = "https://github.com/lewis6991/gitsigns.nvim",
		data = {
			keys = {
				{ lhs = "<leader>gs",  rhs = ":lua require('gitsigns').show_commit()<cr>", mode = "n", desc =  "Git show commit" },
				{ lhs = "]c",   rhs = ":lua require('gitsigns').next_hunk()<cr>", mode = "n", desc =  "Git Next Hunk" },
				{ lhs = "[c",   rhs = ":lua require('gitsigns').prev_hunk()<cr>", mode = "n", desc =  "Prev Next Hunk" },
				{ lhs = "<leader>gb",  rhs = ":lua require('gitsigns').blame_line()<cr>", mode = "n", desc =  "Git Blame" },
				{ lhs = "<leader>gB",  rhs = ":lua require('gitsigns').blame()<cr>", mode = "n", desc =  "Git Blame File" },
				{ lhs = "<leader>gsp",  rhs = ":lua require('gitsigns').preview_hunk_inline()<cr>", mode = "n", desc =  "Preview Hunk" },
				{ lhs = "<leader>ghs", rhs = ":lua require('gitsigns').stage_hunk()<cr>", mode = "n", desc =  "Git Stage Hunk" },
				{ lhs = "<leader>ghr", rhs = ":lua require('gitsigns').reset_hunk()<cr>", mode = "n", desc =  "Git Reset Hunk" },
				{ lhs = "<LocalLeader>gB", rhs = ":GitSigns blame<cr>", mode = "n", desc =  "Git Blame" },
			},
			-- Lazy load only when a buffer is opened or created
			event = { "BufReadPre", "BufNewFile" },

			after = function(_)
				require("gitsigns").setup({})
			end,
		},
	},
}, {
	-- Hand the data over to lze for lazy-loading
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
