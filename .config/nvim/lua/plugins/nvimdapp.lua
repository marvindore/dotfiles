local js_based_languages = {
	"typescript",
	"javascript",
	"typescriptreact",
	"javascriptreact",
	"vue",
}

local home = require("utils").home
local neovim_home = require("utils").neovim_home
local isWindows = require("utils").isWindows

return {
	"mfussenegger/nvim-dap",
	cmd = "DapContinue",
	dependencies = {
		"theHamsta/nvim-dap-virtual-text",
		"nvim-telescope/telescope-dap.nvim",
		"jbyuki/one-small-step-for-vimkind",
		"rcarriga/nvim-dap-ui",
		{
			"microsoft/vscode-js-debug",
			build = isWindows and "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && Move-Item -Path dist -Destination out" or "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
		},
    {
      "leoluz/nvim-dap-go",
      ft = "go",
      config = function (_, opts)
        require("dap-go").setup(opts)
      end
    },
	},
	config = function()
		--https://alpha2phi.medium.com/neovim-dap-enhanced-ebc730ff498b
		require("utils")
		local dap = require("dap")
		local configurations = dap.configurations
		local adapters = dap.adapters

		-- Debug js/ts
		--https://www.youtube.com/watch?v=Ul_WPhS2bis&ab_channel=LazarNikolov
		-- Lua one step mankind plugin
		adapters.nlua = function(callback, config)
			callback({ type = "server", host = config.host or "127.0.0.1", port = 5677 }) --8086
		end

		adapters.local_lua = {
			type = "executable",
			command = "node",
			args = {
				home .. "/projects/local-lua-debugger-vscode/extension/debugAdapter.js",
			},
			enrich_config = function(config, on_config)
				if not config["extensionPath"] then
					local c = vim.deepcopy(config)
					-- 💀 If this is missing or wrong you'll see
					-- "module 'lldebugger' not found" errors in the dap-repl when trying to launch a debug session
					c.extensionPath = home .. "/projects/local-lua-debugger-vscode/"
					on_config(c)
				else
					on_config(config)
				end
			end,
		}

		local lua_port = 5677
		configurations.lua = {
			{
				name = "Current file (local-lua-dbg, lua)",
				type = "local_lua",
				request = "launch",
				cwd = "${workspaceFolder}",
				program = {
					lua = "lua5.1",
					file = "${file}",
				},
				args = {},
			},
			{
				type = "nlua",
				request = "attach",
				port = lua_port,
				name = "Attach to running Neovim instance",
			},
			{
				type = "nlua",
				request = "attach",
				name = "New instance (dotfiles)",
				port = lua_port,
				start_neovim = {
					cwd = home .. "/dotfiles",
					fname = "vim/.config/nvim/init.lua",
				},
			},
			{
				type = "nlua",
				request = "attach",
				name = "New instance (crate/crate)",
				port = lua_port,
				start_neovim = {
					cwd = home .. "/dev/crate/crate",
					fname = "server/src/test/java/io/crate/planner/PlannerTest.java",
				},
			},
			{
				type = "nlua",
				request = "attach",
				name = "New instance (neovim/neovim)",
				port = lua_port,
				start_neovim = {
					cwd = home .. "/dev/neovim/neovim",
					fname = "src/nvim/main.c",
				},
			},
			{
				type = "nlua",
				request = "attach",
				name = "Attach",
				port = function()
					return assert(tonumber(vim.fn.input("Port: ")), "Port is required")
				end,
			},
		}

		-- Python
		adapters.python = {
			type = "executable",
			command = home .. "/.local/share/nvim/mason/packages/debugpy/venv/bin/python",
			args = { "-m", "debugpy.adapter" },
		}

		adapters.generic_remote = function(callback, config)
			callback({
				type = "server",
				host = (config.connect or config).host or "127.0.0.1",
				port = (config.connect or config).port or "5678",
				options = {
					source_filetype = "python",
				},
			})
		end

		configurations.python = {
			{
				type = "python",
				request = "launch",
				name = "launch file",
				program = "${file}",
				pythonPath = function()
					-- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
					-- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
					-- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
					local cwd = vim.fn.getcwd()
					if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
						return cwd .. "/venv/bin/python"
					elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
						return cwd .. "/.venv/bin/python"
					else
						return home .. "/.asdf/shims/python3"
					end
				end,
			},
			{
				type = "generic_remote",
				name = "Generic remote",
				request = "attach",
				justMyCode = false,
				connect = function()
					local host = vim.fn.input("Host [127.0.0.1]: ")
					host = host ~= "" and host or "127.0.0.1"
					local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
					return { host = host, port = port }
				end,
				pathMappings = { {
					localRoot = vim.fn.getcwd(),
					remoteRoot = "/",
				} },
			},
		}
		--
		-- DotNet
		local exe = isWindows and neovim_home .. "/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe"
			or home .. "/mason/bin/netcoredbg"

		adapters.netcoredbg = {
			type = "executable",
			command = exe,
			args = { "--interpreter=vscode" },
		}

		adapters.netcoredbgattach = {
			type = "executable",
			command = exe,
			args = { "--interpreter=vscode", "--attach" },
		}

		configurations.cs = {
			{
				type = "netcoredbg",
				name = "launch dll - netcoredbg",
				request = "launch",
				program = function()
					-- Use telescope to select the DLL file
					local pickers = require("telescope.pickers")
					local finders = require("telescope.finders")
					local sorters = require("telescope.sorters")
					local actions = require("telescope.actions")
					local action_state = require("telescope.actions.state")

					local selected_file = nil

					local co = coroutine.running()
					pickers
						.new({}, {
							prompt_title = "Select DLL",
							finder = finders.new_oneshot_job({
								"rg",
								"--no-ignore",
								"--hidden",
								"--files",
								"-g",
								"*.dll",
								"-g",
								"!**/node_modules/*",
								"-g",
								"!**/.git/*",
							}),
							sorter = sorters.get_fuzzy_file(),
							attach_mappings = function(prompt_bufnr, map)
								actions.select_default:replace(function()
									actions.close(prompt_bufnr)
									selected_file = action_state.get_selected_entry()[1]
									coroutine.resume(co)
								end)
								return true
							end,
						})
						:find()

					coroutine.yield()
					return selected_file
				end,
			},
			{
				type = "netcoredbgattach",
				name = "attach - netcoredbg",
				request = "attach",
				justMyCode = false,
				program = require("dap.utils").pick_process,
			},
		}

		--
		-- Java
		-- configurations.java = {
		--   {
		--     type = 'java';
		--       request = 'attach';
		--       name = 'Remote Attach';
		--       hostName = function()
		--         return vim.fn.input('Enter host (127.0.0.1):')
		--       end;
		--       port = 5005;
		--       },
		--   {
		--       type = 'java';
		--         request = 'launch';
		--         name = 'Run Main';
		--       javaExec = home .. "/.asdf/shims/java",
		--       mainClass = function()
		--         return vim.fn.input('Enter Main class (your.package.name.MainClassName): ')
		--       end
		--       }
		--     }

		--
		-- Typescript
		--
		local jsexe = isWindows and neovim_home .. "/mason/packages/netcoredbg/js-debug-adapter"
			or neovim_home .. "/mason/bin/js-debug-adapter"
		for _, language in ipairs(js_based_languages) do
			configurations[language] = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					program = "$file",
					cwd = "${workspaceFolder}",
					sourceMaps = true,
				}, -- To debug a nodejs process you need to add --inspect when you run the process
				{ -- auto attach to node process running with --inspect
					type = "pwa-node",
					request = "launch",
					name = "PNPM",
					cwd = "${workspaceFolder}",
					runtimeExecutable = "pnpm",
					runtimeArgs = {
						"debug",
					},
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach to 3000",
					address = "localhost",
					port = 3000,
					cwd = "${workspaceFolder}",
					restart = true,
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
					sourceMaps = true,
				},
				-- Debug web application client side
				{
					type = "pwa-chrome",
					request = "launch",
					name = "Launch & Debug Chrome",
					url = function()
						local co = coroutine.running()
						return coroutine.create(function()
							vim.ui.input({
								prompt = "Enter URL: ",
								default = "http://localhost:3000",
							}, function(url)
								if url == nil or url == "" then
									return
								else
									coroutine.resume(co, url)
								end
							end)
						end)
					end,
					webRoot = "${workspaceFolder}",
					skipFiles = { "<node_internals>/**/*.js" },
					protocol = "inspector",
					sourceMaps = true,
					useDataDir = false,
				},
				-- Divider for launch.json derived congigs
				{
					name = "--- launch.json configs below ---",
					type = "",
					request = "launch",
				},
			}
		end

		adapters["pwa-node"] = {
			type = "server",
			host = "::1",
			port = "${port}",
			executable = {
				command = jsexe,
				args = {
					"${port}",
				},
			},
		}

		adapters["pwa-chrome"] = {
			type = "executable",
			command = jsexe,
			args = {},
		}

		require("telescope").load_extension("dap")
		require("nvim-dap-virtual-text").setup({})
		require("dapui").setup({
			-- icons = { expanded = '?', collapsed = '?' },
			icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
			force_buffers = true,
			-- Use this to override mappings for specific elements
			element_mappings = {
				-- Example:
				-- stacks = {
				--   open = "<CR>",
				--   expand = "o",
				-- }
			},
			mappings = {
				-- Use a table to apply multiple mappings
				expand = { "<CR>", "<2-LeftMouse>" },
				open = "o",
				remove = "d",
				edit = "e",
				repl = "r",
				toggle = "t",
			},
			-- Expand lines larger than the window
			-- Requires >= 0.7
			expand_lines = vim.fn.has("nvim-0.7") == 1,
			layouts = {
				{
					elements = {
						-- Elements can be strings or table with id and size keys.
						{ id = "scopes", size = 0.25 },
						"breakpoints",
						"stacks",
						"watches",
					},
					size = 40, -- 40 columns
					position = "left",
				},
				{
					elements = {
						"repl",
						"console",
					},
					size = 0.25, -- 25% of total lines
					position = "bottom",
				},
			},
			controls = {
				enabled = true,
				-- Display controls in this element
				element = "repl",
				icons = {
					pause = "",
					play = "",
					step_into = "",
					step_over = "",
					step_out = "",
					step_back = "",
					run_last = "↻",
					terminate = "□",
				},
			},
			floating = {
				max_height = nil, -- These can be integers or a float between 0 and 1.
				max_width = nil, -- Floats will be treated as percentage of your screen.
				border = "single",
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
			windows = { indent = 1 },
			render = {
				max_type_length = nil, -- Can be integer or nil.
				max_value_lines = 100, -- Can be integer or nil.
			},
		})

		-- nvim-dap-virtual-text. Show virtual text for current frame
		vim.g.dap_virtual_text = true

		-- require('dap').set_log_level('INFO')
		dap.defaults.fallback.terminal_win_cmd = "80vsplit new"
		vim.fn.sign_define("DapBreakpoint", { text = "🟥", texthl = "", linehl = "", numhl = "" })
		vim.fn.sign_define("DapBreakpointRejected", { text = "🟦", texthl = "", linehl = "", numhl = "" })
		vim.fn.sign_define("DapStopped", { text = "⭐️", texthl = "", linehl = "", numhl = "" })
	end,
	keys = {
		{
			"<leader>dO",
			function()
				require("dap").step_out()
			end,
			desc = "Step Out",
		},
		{
			"<leader>do",
			function()
				require("dap").step_over()
			end,
			desc = "Step Over",
		},
		{
			"<leader>da",
			function()
				if vim.fn.filereadable(".vscode/launch.json") then
					local dap_vscode = require("dap.ext.vscode")
					dap_vscode.load_launchjs(nil, {
						["pwa-node"] = js_based_languages,
						["chrome"] = js_based_languages,
						["pwa-chrome"] = js_based_languages,
					})
				end
				require("dap").continue()
			end,
			desc = "Run with Args",
		},
	},
}
