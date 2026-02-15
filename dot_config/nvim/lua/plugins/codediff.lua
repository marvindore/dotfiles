vim.pack.add({
	-- 1. Load the dependency
	"https://github.com/MunifTanjim/nui.nvim",

	-- 2. Define codediff with its lazy-load triggers
	{
		src = "https://github.com/esmuellert/codediff.nvim",
		data = {
			-- Lazy load on command
			cmd = { "CodeDiff" },

			-- Lazy load on keymap (translated to lze format)
			keys = {
				{ lhs = "<leader>D", rhs = "<cmd>CodeDiff<cr>", mode = { "n" }, desc = "Code Diff" },
			},

			-- Run the setup function after the plugin loads
			after = function(_)
				require("codediff").setup({
					highlights = {
						line_insert = "DiffAdd",
						line_delete = "DiffDelete",
						char_insert = nil,
						char_delete = nil,
						char_brightness = nil,
						conflict_sign = nil,
						conflict_sign_resolved = nil,
						conflict_sign_accepted = nil,
						conflict_sign_rejected = nil,
					},
					diff = {
						disable_inlay_hints = true,
						max_computation_time_ms = 5000,
						ignore_trim_whitespace = false,
						hide_merge_artifacts = false,
						original_position = "left",
						conflict_ours_position = "right",
						cycle_next_hunk = true,
					},
					explorer = {
						position = "left",
						width = 40,
						height = 15,
						indent_markers = true,
						initial_focus = "explorer",
						icons = {
							folder_closed = "",
							folder_open = "",
						},
						view_mode = "list",
						file_filter = { ignore = {} },
					},
					history = {
						position = "bottom",
						width = 40,
						height = 15,
						initial_focus = "history",
						view_mode = "list",
					},
					keymaps = {
						view = {
							quit = "q",
							toggle_explorer = "<leader>b",
							next_hunk = "]c",
							prev_hunk = "[c",
							next_file = "]f",
							prev_file = "[f",
							diff_get = "do",
							diff_put = "dp",
							open_in_prev_tab = "gf",
							toggle_stage = "-",
						},
						explorer = {
							select = "<CR>",
							hover = "K",
							refresh = "R",
							toggle_view_mode = "i",
							stage_all = "S",
							unstage_all = "U",
							restore = "X",
						},
						history = {
							select = "<CR>",
							toggle_view_mode = "i",
						},
						conflict = {
							accept_incoming = "<leader>ct",
							accept_current = "<leader>co",
							accept_both = "<leader>cb",
							discard = "<leader>cx",
							next_conflict = "]x",
							prev_conflict = "[x",
							diffget_incoming = "2do",
							diffget_current = "3do",
						},
					},
				})
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
