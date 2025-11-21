local function rebuild_project(co, path)
	local spinner = require("easy-dotnet.ui-modules.spinner").new()
	spinner:start_spinner("Building")
	vim.fn.jobstart(string.format("dotnet build %s", path), {
		on_exit = function(_, return_code)
			if return_code == 0 then
				spinner:stop_spinner("Built successfully")
			else
				spinner:stop_spinner("Build failed with exit code " .. return_code, vim.log.levels.ERROR)
				error("Build failed")
			end
			coroutine.resume(co)
		end,
	})
	coroutine.yield()
end

local js_based_languages = {
	"typescript",
	"javascript",
	"typescriptreact",
	"javascriptreact",
	"vue",
}

return {
	
			--  {
			--      "igorlfs/nvim-dap-view",
			--      ---@module 'dap-view'
			--      ---@type dapview.Config
			--      opts = {},
			--    config = function()
			--    local icons = require("config.icons")
			-- local dap, dapview = require("dap"), require("dap-view")
			-- dapview.setup()
			--
			-- dap.listeners.before.attach.dapui_config = function()
			-- 	dapview.open()
			-- end
			-- dap.listeners.before.launch.dapui_config = function()
			-- 	dapview.open()
			-- end
			-- dap.listeners.before.event_terminated.dapui_config = function()
			-- 	dapview.close()
			-- end
			-- dap.listeners.before.event_exited.dapui_config = function()
			-- 	dapview.close()
			-- end
			--
			-- vim.fn.sign_define("DapBreakpoint", { text = icons.emoji.Anger, texthl = "", linehl = "", numhl = "" })
			-- vim.fn.sign_define("DapBreakpointRejected", { text = icons.emoji.Poop, texthl = "", linehl = "", numhl = "" })
			-- vim.fn.sign_define("DapStopped", { text = icons.emoji.OrangeDiamond, texthl = "", linehl = "", numhl = "" })
			--    end
			--  },

	{
		"mfussenegger/nvim-dap",
		cmd = "DapContinue",
		dependencies = {
			"mfussenegger/nvim-dap-python",
			"igorlfs/nvim-dap-view",
			"jbyuki/one-small-step-for-vimkind",
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
			--local dapview = package.loaded["dap-view"] or require("dap-view")
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

      -- Python
			if vim.g.enablePython then
				local dap_python = require("dap-python")
				dap_python.setup(vim.g.python3_host_prog)
				dap_python.test_runner = "pytest"
				dap_python.default_port = 38000
			end
			--

			if vim.g.enableCsharp then
				--
				-- DotNet
				local exe = vim.g.isWindowsOs
						and vim.g.neovim_home .. "/mason/packages/netcoredbg/netcoredbg/netcoredbg.exe"
					or vim.g.neovim_home .. "/mason/bin/netcoredbg"
				local dotnet = require("easy-dotnet")
				-- local dapview = require("dap-view")
				dap.set_log_level("TRACE")

				-- dap.listeners.before.attach.dapui_config = function()
				-- 	dapview.open()
				-- end
				-- dap.listeners.before.launch.dapui_config = function()
				-- 	dapview.open()
				-- end
				-- dap.listeners.before.event_terminated.dapui_config = function()
				-- 	dapview.close()
				-- end
				-- dap.listeners.before.event_exited.dapui_config = function()
				-- 	dapview.close()
				-- end

				-- vim.keymap.set("n", "q", function()
				-- 	dap.close()
				-- 	dapview.close()
				-- end, {})

				local function file_exists(path)
					local stat = vim.loop.fs_stat(path)
					return stat and stat.type == "file"
				end

				local debug_dll = nil

				local function ensure_dll()
					if debug_dll ~= nil then
						return debug_dll
					end
					local dll = dotnet.get_debug_dll()
					debug_dll = dll
					return dll
				end

				for _, value in ipairs({ "cs", "fsharp" }) do
					dap.configurations[value] = {
						{
							type = "coreclr",
							name = "Program",
							request = "launch",
							env = function()
								local dll = ensure_dll()
								local vars =
									dotnet.get_environment_variables(dll.project_name, dll.absolute_project_path)
								return vars or nil
							end,
							program = function()
								local dll = ensure_dll()
								local co = coroutine.running()
								rebuild_project(co, dll.project_path)
								if not file_exists(dll.target_path) then
									error("Project has not been built, path: " .. dll.target_path)
								end
								return dll.target_path
							end,
							cwd = function()
								local dll = ensure_dll()
								return dll.absolute_project_path
							end,
						},
					}

					dap.listeners.before["event_terminated"]["easy-dotnet"] = function()
						debug_dll = nil
					end

					dap.adapters.coreclr = {
						type = "executable",
						command = "netcoredbg",
						args = { "--interpreter=vscode" },
					}
				end
				-- adapters.netcoredbg = {
				-- 	type = "executable",
				-- 	command = exe,
				-- 	args = { "--interpreter=vscode" },
				-- }
				--
				-- adapters.netcoredbgattach = {
				-- 	type = "executable",
				-- 	command = exe,
				-- 	args = { "--interpreter=vscode", "--attach" },
				-- }
				--
				-- configurations.cs = {
				-- 	{
				-- 		type = "netcoredbg",
				-- 		name = "launch dll - netcoredbg",
				-- 		request = "launch",
				-- 		program = function()
				-- 			-- Select the DLL file to debug
				-- 			local co = coroutine.running()
				-- 			local selected_file = nil
				--
				-- 			require("fzf-lua").files({
				-- 				prompt = "Select DLL> ",
				-- 				-- rg --no-ignore --hidden --files -g '*.dll' -g '!**/node_modules/*' -g '!**/.git/*'
				-- 				cmd = "fd --type f --hidden --no-ignore -e dll --exclude node_modules --exclude .git",
				-- 				actions = {
				-- 					["default"] = function(selected)
				-- 						selected_file = selected[1]
				-- 						coroutine.resume(co)
				-- 					end,
				-- 				},
				-- 			})
				--
				-- 			coroutine.yield()
				-- 			return selected_file
				-- 		end,
				-- 	},
				-- 	{
				-- 		type = "netcoredbgattach",
				-- 		name = "attach - netcoredbg",
				-- 		request = "attach",
				-- 		justMyCode = false,
				-- 		program = require("dap.utils").pick_process,
				-- 	},
				-- }
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
					-- To debug a nodejs process you need to add --inspect when you run the process
					--
				  -- Debug single nodeje file with npm
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file npm",
						program = "$file",
						cwd = "${workspaceFolder}",
						runtimeExecutable = "npm",
						sourceMaps = true,
					}, 
				  -- Debug single nodeje file with pnpm
					{ -- auto attach to node process running with --inspect
						type = "pwa-node",
						request = "launch",
						name = "Launch file pnpm",
						cwd = "${workspaceFolder}",
						runtimeExecutable = "pnpm",
						runtimeArgs = {
							"debug",
						},
					},
					-- Debug node js processes that were ran with the --inspect flag
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
						sourceMaps = true,
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach to localhost:<port>",
						address = "localhost",
						port = function()
							local co = coroutine.running()
							return coroutine.create(function()
								vim.ui.input({ prompt = "Enter port to attach to: ", default = "9229" }, function(input)
									coroutine.resume(co, tonumber(input))
								end)
							end)
						end,
						cwd = "${workspaceFolder}",
						restart = true,
						sourceMaps = true,
						protocol = "inspector",
						skipFiles = { "<node_internals>/**/*.js" },
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
				host = "localhost",
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

			-- require("nvim-dap-virtual-text").setup({})
			--
			-- -- nvim-dap-virtual-text. Show virtual text for current frame
			-- vim.g.dap_virtual_text = true

			-- require('dap').set_log_level('INFO')
			--		dap.defaults.fallback.terminal_win_cmd = "80vsplit new"

			-- Rust

			local extension_path = vim.g.mason_root .. "/packages/codelldb/extension/"
			local codelldb_path = extension_path .. "adapter/codelldb"
			local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
			--local cfg = require("rustaceanvim.config")

			adapters.codelldb = {
				type = "server",
				host = "127.0.0.1",
				port = 13000,
			}

			--			adapters.rustaceanvim = cfg.get_codelldb_adapter(codelldb_path, liblldb_path)
			configurations.rust = {
				{
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					terminal = "integrated",
					stopOnEntry = false,
					args = {},
					sourceLanguages = { "rust" },
				},
				-- {
				-- 	type = "rustaceanvim",
				-- 	name = "rustaceanvim",
				-- 	request = "launch",
				-- 	cwd = "${workspaceFolder}",
				-- 	terminal = "integrated",
				-- 	sourceLanguages = { "rust" },
				-- },
				{
					name = "Debug Rust Executable (Picker)",
					type = "codelldb",
					request = "launch",
					program = function()
						local co = coroutine.running()
						return coroutine.create(function()
							local debug_dir = vim.fn.getcwd() .. "/target/debug"
							local handle = io.popen("find " .. debug_dir .. " -maxdepth 1 -type f -executable")
							local result = handle:read("*a")
							handle:close()

							local files = {}
							for file in result:gmatch("[^\r\n]+") do
								table.insert(files, file)
							end

							vim.ui.select(files, { prompt = "Select Rust executable to debug:" }, function(choice)
								coroutine.resume(co, choice)
							end)
						end)
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
				},
			}
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
				desc = "Run with Args like vscode json",
			},
		},
	},
}
