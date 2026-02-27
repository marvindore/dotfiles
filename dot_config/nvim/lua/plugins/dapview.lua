vim.pack.add({
	{
		src = "https://github.com/igorlfs/nvim-dap-view",
		data = {
			cmd = { "DapViewOpen", "DapViewToggle", "DapViewWatch" },
			on_require = { "dap-view" },
			keys = {
				{ lhs = "<leader>dw",  rhs = ":DapViewWatch<cr>", mode = "n", desc = "Dap Add To Watch List" },
				{ lhs = "<leader>dvb", rhs = ":lua require('dap-view.views').switch_to_view('breakpoints')<cr>", mode = "n", desc = "DapView breakpoints" },
				{ lhs = "<leader>dvs", rhs = ":lua require('dap-view.views').switch_to_view('scopes')<cr>",      mode = "n", desc = "DapView scopes" },
				{ lhs = "<leader>dve", rhs = ":lua require('dap-view.views').switch_to_view('exceptions')<cr>",  mode = "n", desc = "DapView exceptions" },
				{ lhs = "<leader>dvw", rhs = ":lua require('dap-view.views').switch_to_view('watches')<cr>",     mode = "n", desc = "DapView watches" },
				{ lhs = "<leader>dvt", rhs = ":lua require('dap-view.views').switch_to_view('threads')<cr>",     mode = "n", desc = "DapView threads" },
				{ lhs = "<leader>dvr", rhs = ":lua require('dap-view.views').switch_to_view('repl')<cr>",        mode = "n", desc = "DapView repl" },
				{ lhs = "<leader>dvS", rhs = ":lua require('dap-view.views').switch_to_view('sessions')<cr>",    mode = "n", desc = "DapView sessions" },
			},
			after = function(_)
				require("dap-view").setup({
					winbar = {
						show = true,
						sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
						default_section = "watches",
						base_sections = {
							breakpoints = { keymap = "B", label = "Breakpoints [B]" },
							scopes      = { keymap = "S", label = "Scopes [S]" },
							exceptions  = { keymap = "E", label = "Exceptions [E]" },
							watches     = { keymap = "W", label = "Watches [W]" },
							threads     = { keymap = "T", label = "Threads [T]" },
							repl        = { keymap = "R", label = "REPL [R]" },
							sessions    = { keymap = "K", label = "Sessions [K]" },
							console     = { keymap = "C", label = "Console [C]" },
						},
						custom_sections = {},
						controls = {
							enabled  = false,
							position = "right",
							buttons  = {
								"play", "step_into", "step_over", "step_out",
								"step_back", "run_last", "terminate", "disconnect",
							},
						},
					},
					windows = {
						size     = 0.25,
						position = "below",
						terminal = { size = 0.5, position = "left", hide = {} },
					},
					icons = {
						disabled   = "",
						disconnect = "",
						enabled    = "",
						filter     = "󰈲",
						negate     = " ",
						pause      = "",
						play       = "",
						run_last   = "",
						step_back  = "",
						step_into  = "",
						step_out   = "",
						step_over  = "",
						terminate  = "",
					},
					help        = { border = nil },
					switchbuf   = "usetab",
					auto_toggle = false,
					follow_tab  = false,
				})

				local icons = require("config.icons")
				vim.fn.sign_define("DapBreakpoint",         { text = icons.emoji.Anger,        texthl = "", linehl = "", numhl = "" })
				vim.fn.sign_define("DapBreakpointRejected", { text = icons.emoji.Poop,         texthl = "", linehl = "", numhl = "" })
				vim.fn.sign_define("DapStopped",            { text = icons.emoji.OrangeDiamond, texthl = "", linehl = "", numhl = "" })
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
