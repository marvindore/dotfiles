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
	{
		"mfussenegger/nvim-dap",
		cmd = { "DapContinue", "DapToggleBreakpoint" },
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
				config = function(_, opts)
					require("dap-go").setup(opts)
				end,
			},
		},
		config = function()
			local dap = require("dap")
			local configurations = dap.configurations
			local adapters = dap.adapters

			-- =========================================
			-- Lua Setup
			-- =========================================
			adapters.nlua = function(callback, config)
				callback({ type = "server", host = config.host or "127.0.0.1", port = 5677 })
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
					name = "Attach",
					port = function()
						return assert(tonumber(vim.fn.input("Port: ")), "Port is required")
					end,
				},
			}

			-- =========================================
			-- Python Setup
			-- =========================================
			if vim.g.enablePython then
				local dap_python = require("dap-python")
				dap_python.setup(vim.g.python3_host_prog)
				dap_python.test_runner = "pytest"
				dap_python.default_port = 38000
			end

			-- =========================================
			-- C# / DotNet Setup
			-- =========================================
			if vim.g.enableCsharp then
				dap.set_log_level("TRACE")

				local function file_exists(path)
					local stat = vim.loop.fs_stat(path)
					return stat and stat.type == "file"
				end

				local debug_dll = nil

				local function ensure_dll()
					if debug_dll ~= nil then
						return debug_dll
					end
					-- Lazy load: Only require when actually debugging
					local dotnet = require("easy-dotnet")
					local dll = dotnet.get_debug_dll()
					debug_dll = dll
					return dll
				end

				-- Define Adapter Once
				dap.adapters.coreclr = {
					type = "executable",
					command = "netcoredbg",
					args = { "--interpreter=vscode" },
				}

				-- Define Listener Once
				dap.listeners.before["event_terminated"]["easy-dotnet"] = function()
					debug_dll = nil
				end

				-- Define Configurations for both languages
				for _, lang in ipairs({ "cs", "fsharp" }) do
					dap.configurations[lang] = {
						{
							type = "coreclr",
							name = "Launch - " .. lang,
							request = "launch",
							env = function()
								local dll = ensure_dll()
								-- Lazy require here to get env vars
								local dotnet = require("easy-dotnet")
								local vars = dotnet.get_environment_variables(dll.project_name, dll.absolute_project_path)
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
				end
			end

			-- =========================================
			-- Typescript / Javascript Setup
			-- =========================================
			local jsexe = vim.g.isWindowsOs and vim.g.neovim_home .. "/mason/packages/netcoredbg/js-debug-adapter"
				or vim.g.neovim_home .. "/mason/bin/js-debug-adapter"

			for _, language in ipairs(js_based_languages) do
				configurations[language] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file npm",
						program = "$file",
						cwd = "${workspaceFolder}",
						runtimeExecutable = "npm",
						sourceMaps = true,
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file pnpm",
						cwd = "${workspaceFolder}",
						runtimeExecutable = "pnpm",
						runtimeArgs = { "debug" },
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
						sourceMaps = true,
					},
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
				}
			end

			adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = jsexe,
					args = { "${port}" },
				},
			}

			adapters["pwa-chrome"] = {
				type = "executable",
				command = jsexe,
				args = {},
			}

			-- =========================================
			-- Rust Setup
			-- =========================================
			adapters.codelldb = {
				type = "server",
				host = "127.0.0.1",
				port = 13000,
			}

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
