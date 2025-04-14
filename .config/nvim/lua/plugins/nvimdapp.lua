local js_based_languages = {
	"typescript",
	"javascript",
	"typescriptreact",
	"javascriptreact",
	"vue",
}

return {
	"mfussenegger/nvim-dap",
	cmd = "DapContinue",
	dependencies = {
		"mfussenegger/nvim-dap-python",
		"theHamsta/nvim-dap-virtual-text",
		"jbyuki/one-small-step-for-vimkind",
		{ "igorlfs/nvim-dap-view", opts = {} },
		{
			"microsoft/vscode-js-debug",
			build = vim.g.isWindowsOs
					and "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && Move-Item -Path dist -Destination out"
				or "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
		},
		{
			"leoluz/nvim-dap-go",
			ft = "go",
			config = function(_, opts)
				require("dap-go").setup(opts)
			end,
		},
	},
	config = function()
		--https://alpha2phi.medium.com/neovim-dap-enhanced-ebc730ff498b
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
				vim.g.homeDir .. "/projects/local-lua-debugger-vscode/extension/debugAdapter.js",
			},
			enrich_config = function(config, on_config)
				if not config["extensionPath"] then
					local c = vim.deepcopy(config)
					-- 💀 If this is missing or wrong you'll see
					-- "module 'lldebugger' not found" errors in the dap-repl when trying to launch a debug session
					c.extensionPath = vim.g.homeDir .. "/projects/local-lua-debugger-vscode/"
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
					cwd = vim.g.homeDir .. "/dotfiles",
					fname = "vim/.config/nvim/init.lua",
				},
			},
			{
				type = "nlua",
				request = "attach",
				name = "New instance (crate/crate)",
				port = lua_port,
				start_neovim = {
					cwd = vim.g.homeDir .. "/dev/crate/crate",
					fname = "server/src/test/java/io/crate/planner/PlannerTest.java",
				},
			},
			{
				type = "nlua",
				request = "attach",
				name = "New instance (neovim/neovim)",
				port = lua_port,
				start_neovim = {
					cwd = vim.g.homeDir .. "/dev/neovim/neovim",
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

		if vim.g.enablePython then
			local dap_python = require("dap-python")
			dap_python.setup(vim.g.neovim_home .. "/mason/packages/debugpy/venv/bin/python")
			dap_python.test_runner = "pytest"
			dap_python.default_port = 38000

			dap.listeners.after.event_initialized["dapview_config"] = function()
				require("dap-view").open()
			end
			dap.listeners.before.event_terminated["dapview_config"] = function()
				require("dap-view").close()
			end
			dap.listeners.before.event_exited["dapview_config"] = function()
				require("dap-view").close()
			end
		end

		if vim.g.enableCsharp then
			--
			-- DotNet
			local exe = vim.g.isWindowsOs
					and vim.g.neovim_home .. "/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe"
				or vim.g.neovim_home .. "/mason/bin/netcoredbg"

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
						-- Select the DLL file to debug
						local co = coroutine.running()
						local selected_file = nil

						require("fzf-lua").files({
							prompt = "Select DLL> ",
							-- rg --no-ignore --hidden --files -g '*.dll' -g '!**/node_modules/*' -g '!**/.git/*'
							cmd = "fd --type f --hidden --no-ignore -e dll --exclude node_modules --exclude .git",
							actions = {
								["default"] = function(selected)
									selected_file = selected[1]
									coroutine.resume(co)
								end,
							},
						})

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
		end

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
		local jsexe = vim.g.isWindowsOs and vim.g.neovim_home .. "/mason/packages/netcoredbg/js-debug-adapter"
			or vim.g.neovim_home .. "/mason/bin/js-debug-adapter"

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

		require("nvim-dap-virtual-text").setup({})

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
