vim.pack.add({
	"https://github.com/nvim-tree/nvim-web-devicons",
	{
		src = "https://github.com/dlyongemallo/diffview.nvim",
		data = {
			cmd = {
				"DiffviewOpen",
				"DiffviewClose",
				"DiffviewToggle",
				"DiffviewFileHistory",
				"DiffviewFocusFiles",
				"DiffviewToggleFiles",
				"DiffviewRefresh",
			},
			on_require = { "diffview" },
			keys = {
				{ lhs = "<leader>D",  rhs = ":DiffviewOpen<cr>",           mode = "n", desc = "Git Project Diff" },
				{ lhs = "<leader>gs", rhs = ":DiffviewFileHistory %<cr>",  mode = "n", desc = "Git File History" },
				{ lhs = "<leader>dh", rhs = ":DiffviewFileHistory<cr>",    mode = "n", desc = "Git Repo History" },
				{ lhs = "<leader>dc", rhs = ":DiffviewClose<cr>",          mode = "n", desc = "Git Close Diff" },
			},
			after = function(_)
				require("diffview").setup({
					enhanced_diff_hl = true,
					view = {
						default    = { layout = "diff2_horizontal" },
						merge_tool = { layout = "diff3_horizontal", disable_diagnostics = true },
					},
					file_panel = {
						listing_style = "tree",
						win_config    = { position = "left", width = 35 },
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
