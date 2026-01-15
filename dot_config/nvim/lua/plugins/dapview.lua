return {
	{
		"igorlfs/nvim-dap-view",
		---@module 'dap-view'
		---@type dapview.Config
		opts = {
			winbar = {
				show = true,
				-- You can add a "console" section to merge the terminal with the other views
				sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
				-- Must be one of the sections declared above (except for "console")
				default_section = "watches",
				-- Configure each section individually
				base_sections = {
					breakpoints = {
						keymap = "B",
						label = "Breakpoints [B]",
						short_label = " [B]",
						action = function()
							require("dap-view.views").switch_to_view("breakpoints")
						end,
					},
					scopes = {
						keymap = "S",
						label = "Scopes [S]",
						short_label = "󰂥 [S]",
						action = function()
							require("dap-view.views").switch_to_view("scopes")
						end,
					},
					exceptions = {
						keymap = "E",
						label = "Exceptions [E]",
						short_label = "󰢃 [E]",
						action = function()
							require("dap-view.views").switch_to_view("exceptions")
						end,
					},
					watches = {
						keymap = "W",
						label = "Watches [W]",
						short_label = "󰛐 [W]",
						action = function()
							require("dap-view.views").switch_to_view("watches")
						end,
					},
					threads = {
						keymap = "T",
						label = "Threads [T]",
						short_label = "󱉯 [T]",
						action = function()
							require("dap-view.views").switch_to_view("threads")
						end,
					},
					repl = {
						keymap = "R",
						label = "REPL [R]",
						short_label = "󰯃 [R]",
						action = function()
							require("dap-view.repl").show()
						end,
					},
					sessions = {
						keymap = "K", -- I ran out of mnemonics
						label = "Sessions [K]",
						short_label = " [K]",
						action = function()
							require("dap-view.views").switch_to_view("sessions")
						end,
					},
					console = {
						keymap = "C",
						label = "Console [C]",
						short_label = "󰆍 [C]",
						action = function()
							require("dap-view.term").show()
						end,
					},
				},
				-- Add your own sections
				custom_sections = {},
				controls = {
					enabled = false,
					position = "right",
					buttons = {
						"play",
						"step_into",
						"step_over",
						"step_out",
						"step_back",
						"run_last",
						"terminate",
						"disconnect",
					},
					custom_buttons = {},
				},
			},
			windows = {
				height = 0.25,
				position = "below",
				terminal = {
					width = 0.5,
					position = "right",
					-- List of debug adapters for which the terminal should be ALWAYS hidden
					hide = {},
					-- Hide the terminal when starting a new session
					start_hidden = true,
				},
			},
			icons = {
				disabled = "",
				disconnect = "",
				enabled = "",
				filter = "󰈲",
				negate = " ",
				pause = "",
				play = "",
				run_last = "",
				step_back = "",
				step_into = "",
				step_out = "",
				step_over = "",
				terminate = "",
			},
			help = {
				border = nil,
			},
			-- Controls how to jump when selecting a breakpoint or navigating the stack
			switchbuf = "usetab",
			auto_toggle = false,
			-- Reopen dapview when switching tabs
			follow_tab = false,
		},
		-- 1. Accept opts from Lazy
		config = function(_, opts)
			-- 2. Initialize the plugin with your opts
			require("dap-view").setup(opts)

			local dap = require("dap")
			local dapview = require("dap-view")
			local icons = require("config.icons")

			dap.listeners.before.attach.dapui_config = function()
				dapview.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapview.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapview.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapview.close()
			end

			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = icons.emoji.Anger, texthl = "", linehl = "", numhl = "" }
			)
			vim.fn.sign_define(
				"DapBreakpointRejected",
				{ text = icons.emoji.Poop, texthl = "", linehl = "", numhl = "" }
			)
			vim.fn.sign_define(
				"DapStopped",
				{ text = icons.emoji.OrangeDiamond, texthl = "", linehl = "", numhl = "" }
			)
		end,
	},
}
