vim.pack.add({
	{
		src = "https://github.com/igorlfs/nvim-dap-view",
		data = {
			cmd = { "DapViewOpen", "DapViewClose", "DapViewToggle", "DapViewWatch", "DapViewJump" },
			on_require = { "dap-view" },
			keys = {
				{ lhs = "<leader>dw",  rhs = ":DapViewWatch<cr>",            mode = "n", desc = "Dap Add To Watch List" },
				{ lhs = "<leader>dvb", rhs = ":DapViewJump breakpoints<cr>", mode = "n", desc = "DapView breakpoints" },
				{ lhs = "<leader>dvs", rhs = ":DapViewJump scopes<cr>",      mode = "n", desc = "DapView scopes" },
				{ lhs = "<leader>dve", rhs = ":DapViewJump exceptions<cr>",  mode = "n", desc = "DapView exceptions" },
				{ lhs = "<leader>dvw", rhs = ":DapViewJump watches<cr>",     mode = "n", desc = "DapView watches" },
				{ lhs = "<leader>dvt", rhs = ":DapViewJump threads<cr>",     mode = "n", desc = "DapView threads" },
				{ lhs = "<leader>dvr", rhs = ":DapViewJump repl<cr>",        mode = "n", desc = "DapView repl" },
				{ lhs = "<leader>dvS", rhs = ":DapViewJump sessions<cr>",    mode = "n", desc = "DapView sessions" },
				{ lhs = "<leader>dvc", rhs = ":DapViewJump console<cr>",     mode = "n", desc = "DapView console" },
			},
			after = function(_)
				require("dap-view").setup({
					winbar = {
						show = true,
						sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
						default_section = "scopes",
						-- Hints are appended to labels automatically (e.g., "Watches [W]")
						show_keymap_hints = true,
						controls = {
							enabled = false,
						},
					},
					windows = {
						-- Fraction < 1 is a percentage of the editor width
						size = 0.45,
						-- "right" opens the view as a vertical split on the right
						position = "right",
						terminal = {
							size = 0.5,
							position = "left",
							-- NOTE: standalone terminal window is suppressed automatically
							-- when "console" is listed in winbar.sections above.
							-- dap-view skips opening it when has_console = true.
							hide = {},
						},
					},
					switchbuf = "usetab",
					auto_toggle = true,
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
