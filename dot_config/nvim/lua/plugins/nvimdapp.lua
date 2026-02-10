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
				build = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)
						and 'npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && powershell -NoProfile -Command "if (Test-Path out) { Remove-Item -Recurse -Force out }; Move-Item -Path dist -Destination out"'
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

			----------------------------------------------------------------------
			-- Helpers (shared)
			----------------------------------------------------------------------
			local function file_exists(path)
				local st = vim.loop.fs_stat(path)
				return st and st.type == "file"
			end

			local function resolve_first_existing(paths)
				for _, p in ipairs(paths) do
					if file_exists(p) then
						return p
					end
				end
			end

			local function find_upward(start_dir, glob)
				-- Search upward for the first dir that has a match for glob
				local dir = start_dir
				while dir and dir ~= "" do
					local matches = vim.fn.glob(dir .. "/" .. glob, true, true)
					if matches and #matches > 0 then
						return dir, matches
					end
					local parent = vim.fn.fnamemodify(dir, ":h")
					if parent == dir then
						break
					end
					dir = parent
				end
				return start_dir, {}
			end

			local function detect_project_root()
				local cwd = vim.fn.getcwd()
				local dir, csprojs = find_upward(cwd, "*.csproj")
				if #csprojs > 0 then
					return dir, csprojs[1]
				end
				local sdir, slns = find_upward(cwd, "*.sln")
				if #slns > 0 then
					return sdir, slns[1]
				end
				return cwd, nil
			end

			local function list_candidate_dlls(project_root)
				-- Prefer Debug builds; include Release as fallback
				local globs = {
					project_root .. "/**/bin/Debug*/net*/*.dll",
					project_root .. "/**/bin/Release*/net*/*.dll",
				}
				local out = {}
				local seen = {}
				for _, pat in ipairs(globs) do
					local matches = vim.fn.glob(pat, true, true) or {}
					for _, f in ipairs(matches) do
						-- Filter out ref assemblies and design-time/temp dlls
						if
							not f:match("/ref/")
							and not f:match("\\ref\\")
							and not f:match("%.vshost%.dll$")
							and not f:match("%.deps%.dll$")
							and not f:match("[/\\]TestHost[%.]dll$")
						then
							if not seen[f] then
								table.insert(out, f)
								seen[f] = true
							end
						end
					end
				end
				-- Sort newest first
				table.sort(out, function(a, b)
					local sa, sb = vim.loop.fs_stat(a), vim.loop.fs_stat(b)
					local ma = sa and sa.mtime and sa.mtime.sec or 0
					local mb = sb and sb.mtime and sb.mtime.sec or 0
					return ma > mb
				end)
				return out
			end

			-- Return `true` if fzf-lua handled the picker, `false` otherwise
			local function pick_with_fzf(items, prompt, on_choice)
				local ok, fzf = pcall(require, "fzf-lua")
				if not ok then
					return false
				end

				-- Ensure on_choice is callable (defensive)
				if type(on_choice) ~= "function" then
					vim.notify("pick_with_fzf: on_choice is not a function", vim.log.levels.ERROR)
					return false
				end

				fzf.fzf_exec(items, {
					prompt = (prompt or "Select > ") .. " ",
					actions = {
						["default"] = function(selected)
							local choice
							if type(selected) == "table" then
								-- fzf-lua passes an array of selected lines
								choice = selected[1]
							end
							on_choice(choice)
						end,
						-- graceful cancel paths
						["esc"] = function()
							on_choice(nil)
						end,
						["ctrl-c"] = function()
							on_choice(nil)
						end,
					},
				})
				return true
			end

			local function pick_dll(items, on_choice)
				if not items or #items == 0 then
					on_choice(nil)
					return
				end
				-- ✅ Pass on_choice through to fzf
				if pick_with_fzf(items, "Select DLL", on_choice) then
					return
				end
				-- Fallback to vim.ui.select
				vim.ui.select(items, { prompt = "Select DLL to run:" }, function(choice)
					on_choice(choice)
				end)
			end

			local function build_then_pick_dll(target, project_root, on_result)
				local build_target = target
				if not build_target or build_target == "" then
					build_target = project_root
				end
				vim.fn.jobstart({ "dotnet", "build", build_target }, {
					stdout_buffered = true,
					stderr_buffered = true,
					on_exit = function(_, rc)
						if rc ~= 0 then
							vim.schedule(function()
								vim.notify("dotnet build failed (" .. tostring(rc) .. ")", vim.log.levels.ERROR)
							end)
							on_result(nil)
							return
						end
						local dlls = list_candidate_dlls(project_root)
						vim.schedule(function()
							if #dlls == 0 then
								vim.notify("Build succeeded but no DLLs found under bin/", vim.log.levels.WARN)
								on_result(nil)
							else
								pick_dll(dlls, function(choice)
									on_result(choice)
								end)
							end
						end)
					end,
				})
			end

			----------------------------------------------------------------------
			-- Lua
			----------------------------------------------------------------------
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

			----------------------------------------------------------------------
			-- Python
			----------------------------------------------------------------------
			if vim.g.enablePython then
				local dap_python = require("dap-python")
				dap_python.setup(vim.g.python3_host_prog)
				dap_python.test_runner = "pytest"
				dap_python.default_port = 38000
			end

			----------------------------------------------------------------------
			-- C# / .NET  (nvim-dap with Build ➜ filtered DLL picker)
			----------------------------------------------------------------------
			local dap = require("dap")
			dap.set_log_level("TRACE")

			local function resolve_netcoredbg()
				local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) == 1
				local data = vim.fn.stdpath("data")
				local paths = {}

				-- Mason package dir
				local ok, mr = pcall(require, "mason-registry")
				if ok then
					local ok_pkg, pkg = pcall(function()
						return mr.get_package("netcoredbg")
					end)
					if ok_pkg and type(pkg) == "table" then
						local base = nil
						if type(pkg.get_install_path) == "function" then
							base = pkg:get_install_path()
						elseif type(pkg.install_path) == "string" then
							base = pkg.install_path
						end
						if base then
							table.insert(
								paths,
								is_win and (base .. "\\netcoredbg\\netcoredbg.exe")
									or (base .. "/netcoredbg/netcoredbg")
							)
						end
					end
				end
				-- Mason bin shims
				if is_win then
					table.insert(paths, data .. "\\mason\\packages\\netcoredbg\\netcoredbg\\netcoredbg.exe")
					table.insert(paths, data .. "\\mason\\bin\\netcoredbg.exe")
				else
					table.insert(paths, data .. "/mason/packages/netcoredbg/netcoredbg/netcoredbg")
					table.insert(paths, data .. "/mason/bin/netcoredbg")
				end
				-- PATH fallback
				table.insert(paths, is_win and "netcoredbg.exe" or "netcoredbg")

				return resolve_first_existing(paths) or paths[#paths]
			end

			dap.adapters.coreclr = {
				type = "executable",
				command = resolve_netcoredbg(),
				args = { "--interpreter=vscode" },
			}

			-- Track last chosen dll so we can compute cwd around it
			local last_picked_dll = nil

			-- Helper: return true if a dll looks runnable (has a sibling .runtimeconfig.json and is not a test)
			local function is_runnable_dll(dll)
				if not dll or dll == "" then
					return false
				end
				-- Exclude anything with "Tests" in name or path
				if dll:match("[/\\]Tests[/\\]") or dll:match("Tests") then
					return false
				end
				-- Executable projects produce a runtimeconfig.json; libraries generally don't
				local runtimeconfig = dll:gsub("%.dll$", ".runtimeconfig.json")
				return file_exists(runtimeconfig)
			end

			local function list_candidate_dlls(project_root)
				local globs = {
					project_root .. "/**/bin/Debug*/net*/*.dll",
					project_root .. "/**/bin/Release*/net*/*.dll",
				}
				local out, seen = {}, {}
				for _, pat in ipairs(globs) do
					local matches = vim.fn.glob(pat, true, true) or {}
					for _, f in ipairs(matches) do
						if
							not f:match("/ref/")
							and not f:match("\\ref\\")
							and not f:match("%.vshost%.dll$")
							and not f:match("%.deps%.dll$")
							and not f:match("[/\\]testhost[%.]dll$")
							and is_runnable_dll(f)
						then
							if not seen[f] then
								table.insert(out, f)
								seen[f] = true
							end
						end
					end
				end
				table.sort(out, function(a, b)
					local sa, sb = vim.loop.fs_stat(a), vim.loop.fs_stat(b)
					local ma = sa and sa.mtime and sa.mtime.sec or 0
					local mb = sb and sb.mtime and sb.mtime.sec or 0
					return ma > mb
				end)
				return out
			end

			-- Unchanged: detect_project_root()
			-- Unchanged: pick_with_fzf(), pick_dll()

			local function build_then_pick_dll(target, project_root, on_result)
				local build_target = (target and target ~= "") and target or project_root
				vim.fn.jobstart({ "dotnet", "build", build_target }, {
					stdout_buffered = true,
					stderr_buffered = true,
					on_exit = function(_, rc)
						if rc ~= 0 then
							vim.schedule(function()
								vim.notify("dotnet build failed (" .. tostring(rc) .. ")", vim.log.levels.ERROR)
							end)
							on_result(nil)
							return
						end
						local dlls = list_candidate_dlls(project_root)
						vim.schedule(function()
							if #dlls == 0 then
								vim.notify("Build succeeded but no runnable DLLs found under bin/", vim.log.levels.WARN)
								on_result(nil)
							else
								pick_dll(dlls, function(choice)
									last_picked_dll = choice
									on_result(choice)
								end)
							end
						end)
					end,
				})
			end

			-- Compute cwd from last_picked_dll:
			-- Prefer the directory containing the dll (bin/.../netX.Y).
			-- Or walk up to the project dir (strip /bin/Debug...).
			local function cwd_for_last_pick()
				if not last_picked_dll then
					local root = select(1, detect_project_root())
					return root
				end
				-- dir of the dll
				local bin_dir = vim.fn.fnamemodify(last_picked_dll, ":h")
				-- project dir (strip /bin/Debug* or /bin/Release* from the path)
				local project_dir = last_picked_dll:match("^(.*)[/\\]bin[/\\][^/\\]+[/\\]net[^/\\]+[/\\][^/\\]+$")
				return project_dir or bin_dir
			end

			local function coreclr_build_then_pick(name_suffix)
				return {
					type = "coreclr",
					name = "CoreCLR: Build & Pick (" .. name_suffix .. ")",
					request = "launch",

					cwd = function()
						return cwd_for_last_pick()
					end,

					env = {
						ASPNETCORE_ENVIRONMENT = "Development",
						DOTNET_ENVIRONMENT = "Development",
					},

					-- TIP: netcoredbg ignores some VS Code "console" settings. If you want a real terminal:
					-- externalConsole = true,

					stopAtEntry = false,
					justMyCode = true,

					program = function()
						local project_root, project_file = detect_project_root()
						local co = coroutine.running()
						build_then_pick_dll(project_file or project_root, project_root, function(dll)
							coroutine.resume(co, dll)
						end)
						return coroutine.yield()
					end,
				}
			end

			for _, lang in ipairs({ "cs", "csharp", "fsharp" }) do
				configurations[lang] = configurations[lang] or {}
				table.insert(configurations[lang], coreclr_build_then_pick("fzf/ui"))
				table.insert(configurations[lang], coreclr_build_then_pick("alt"))
			end
			----------------------------------------------------------------------
			-- Typescript / Javascript
			----------------------------------------------------------------------
			local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)
			local mason_bin = vim.fn.stdpath("data") .. (is_win and "\\mason\\bin\\" or "/mason/bin/")
			local jsexe = is_win and (mason_bin .. "js-debug-adapter.cmd") or (mason_bin .. "js-debug-adapter")

			for _, language in ipairs(js_based_languages) do
				configurations[language] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file npm",
						program = "${file}",
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
							local current = coroutine.running()
							vim.ui.input({
								prompt = "Enter URL: ",
								default = "http://localhost:3000",
							}, function(url)
								coroutine.resume(current, url or "")
							end)
							return coroutine.yield()
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

			----------------------------------------------------------------------
			-- Rust
			----------------------------------------------------------------------
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
						local current = coroutine.running()
						vim.ui.input({
							prompt = "Path to executable: ",
							default = vim.fn.getcwd() .. "/",
						}, function(path)
							coroutine.resume(current, path)
						end)
						return coroutine.yield()
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
						local current = coroutine.running()
						local debug_dir = vim.fn.getcwd() .. "/target/debug"
						local handle = io.popen("find " .. debug_dir .. " -maxdepth 1 -type f -perm -111 2>/dev/null")
						local result = handle and handle:read("*a") or ""
						if handle then
							handle:close()
						end

						local files = {}
						for file in result:gmatch("[^\r\n]+") do
							table.insert(files, file)
						end

						vim.ui.select(files, { prompt = "Select Rust executable to debug:" }, function(choice)
							coroutine.resume(current, choice)
						end)
						return coroutine.yield()
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
				},
			}

			-- VS Code-style launch.json support (coreclr + js mappings)
			local dap_vscode = require("dap.ext.vscode")
			dap_vscode.load_launchjs(nil, {
				coreclr = { "cs", "csharp", "fsharp" },
				["pwa-node"] = js_based_languages,
				["chrome"] = js_based_languages,
				["pwa-chrome"] = js_based_languages,
			})
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

			-- Load VSCode-style configs (if present) and continue
			{
				"<leader>da",
				function()
					if vim.fn.filereadable(".vscode/launch.json") == 1 then
						local dap_vscode = require("dap.ext.vscode")
						dap_vscode.load_launchjs(nil, {
							coreclr = { "cs", "csharp", "fsharp" },
							["pwa-node"] = js_based_languages,
							["chrome"] = js_based_languages,
							["pwa-chrome"] = js_based_languages,
						})
					end
					require("dap").continue()
				end,
				desc = "Run with Args (VSCode-style)",
			},
		},
	},
}
