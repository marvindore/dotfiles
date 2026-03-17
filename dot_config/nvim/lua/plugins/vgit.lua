vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	{
		src = "https://github.com/tanvirtin/vgit.nvim",
		data = {
			event = { "VimEnter" },
			after = function(_)
				require("vgit").setup()

				local set = vim.keymap.set

				-- Hunk navigation (replaces gitsigns ]c / [c)
				set("n", "]c", function() require("vgit").hunk_down() end, { desc = "Git Next Hunk" })
				set("n", "[c", function() require("vgit").hunk_up() end, { desc = "Git Prev Hunk" })

				-- Blame (replaces gitsigns <leader>gb / <leader>gB)
				set("n", "<leader>gb", function() require("vgit").buffer_blame_preview() end, { desc = "Git Blame Line" })
				set("n", "<leader>gB", function() require("vgit").toggle_live_blame() end, { desc = "Git Toggle Live Blame" })

				-- File history (replaces gitsigns <leader>gs show_commit)
				set("n", "<leader>gs", function() require("vgit").buffer_history_preview() end, { desc = "Git File History" })

				-- Hunk preview (replaces gitsigns <leader>gsp preview_hunk_inline)
				set("n", "<leader>gsp", function() require("vgit").buffer_hunk_preview() end, { desc = "Git Preview Hunk" })

				-- Stage / reset hunk (replaces gitsigns <leader>ghs / <leader>ghr)
				set("n", "<leader>ghs", function() require("vgit").buffer_hunk_stage() end, { desc = "Git Stage Hunk" })
				set("n", "<leader>ghr", function() require("vgit").buffer_hunk_reset() end, { desc = "Git Reset Hunk" })

				-- Project diff (replaces codediff <leader>D)
				set("n", "<leader>D", function() require("vgit").project_diff_preview() end, { desc = "Git Project Diff" })
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
