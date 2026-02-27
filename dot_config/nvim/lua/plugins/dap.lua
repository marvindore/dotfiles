local js_langs = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" }

vim.pack.add({
	-- 1. DAP Adapters and UI (Safely tucked away in opt/)
	{ src = "https://github.com/mfussenegger/nvim-dap-python", data = { on_require = { "dap-python" } } },
	{ src = "https://github.com/jbyuki/one-small-step-for-vimkind", data = { on_require = { "osv" } } },
	{ src = "https://github.com/leoluz/nvim-dap-go", data = { on_require = { "dap-go" } } },
	{
		src = "https://github.com/microsoft/vscode-js-debug",
		data = {
			-- Lazy load this massive binary folder only when you open a JS/TS file
			ft = js_langs,
			run = function(p)
				local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)
				local cmd = is_win
						and 'npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && powershell -NoProfile -Command "if (Test-Path out) { Remove-Item -Recurse -Force out }; Move-Item -Path dist -Destination out"'
					or "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out"
				vim.system({ "bash", "-c", cmd }, { cwd = p.spec.path }):wait()
			end,
		},
	},

	-- 2. Main Debugger
	{
		src = "https://github.com/mfussenegger/nvim-dap",
		data = {
			-- Wake up the core engine if you require it, or run these commands/keys
			on_require = { "dap" },
			cmd = { "DapContinue", "DapToggleBreakpoint" },
			keys = {
				{ lhs = "<leader>dn", rhs = ":lua require('osv').launch({port = 5677})<CR>", mode = "n", desc =  "Debug Neovim-kind" }, -- one step for vim kind debugger
				{ lhs = "<F5>", rhs = ":lua require('dap').continue()<CR>", mode = "n", desc =  "Debug continue" },
				{ lhs = "<S-F5>", rhs = ":lua require'dap'.close()<cr>", mode = "n", desc =  "Debug stop" },

				{ lhs = "<F10>", rhs = ":lua require('dap').step_over()<CR>", mode = "n", desc =  "Debug step over" },
				{ lhs = "<F11>", rhs = ":lua require('dap').step_into()<CR>", mode = "n", desc =  "Debug step into" },
				{ lhs = "<S-F11>", rhs = ":lua require('dap').step_out()<CR>", mode = "n", desc =  "Debug step out" },
				{ lhs = "<leader>do", rhs = ":lua require('dap').step_over()<CR>", mode = "n", desc =  "Debug step over" },
				{ lhs = "<leader>dO", rhs = ":lua require('dap').step_out()<CR>", mode = "n", desc =  "Debug step out" },

				{
					lhs = "<leader>db",
					rhs = ":lua require('utils.dap_breakpoints').toggle_breakpoint()<CR>",
					mode = "n",
					desc = "Debug toggle breakpoint",
				},
				{ lhs = "<leader>dr", rhs = ":lua require'dap'.restart()<cr>", mode = "n", desc =  "Debug restart" },
				{ lhs = "<leader>ds", rhs = ":lua require'dap'.step_over()<cr>", mode = "n", desc =  "Step over" },
				{ lhs = "<leader>dS", rhs = ":lua require'dap'.stop()<cr>", mode = "n", desc =  "Debug step over" },
				{ lhs = "<leader>dT", rhs = ":lua require'dap'.terminate()<cr>", mode = "n", desc =  "Debug terminate" },
				{ lhs = "<leader>dC", rhs = ":lua require'dap'.clear_breakpoints()<CR>", mode = "n", desc =  "Debug clear breakpoints" },
				{ lhs = "<leader>dX", rhs = ":lua require'dap'.close()<CR>", mode = "n", desc =  "Debug close" },
				{ lhs = "<leader>dc", rhs = ":lua require'dap'.continue()<CR>", mode = "n", desc =  "Debug continue" },
				{ lhs = "<leader>dU", rhs = ":lua require'dap'.up()<CR>", mode = "n", desc =  "Debug up" },
				{ lhs = "<leader>dui",rhs =  ":lua require'dap-view'.toggle()<CR>", mode = "n", desc =  "Debug up" },
				{ lhs = "<leader>dd", rhs = ":lua require'dap'.clear_breakpoints()<CR>", mode = "n", desc =  "Delete all breakpoints" },
				{ lhs = "<leader>dD", rhs = ":lua require'dap'.down()<CR>", mode = "n", desc =  "Debug down" },
				{
					lhs = "<leader>d_",
					rhs = ":lua require'dap'.disconnect();require'dap'.stop();require'dap'.run_last()<CR>",
					mode = "n",
					desc = "Debug stop run last",
				},

				{
					lhs = "<leader>dR",
					rhs = ":lua require'dap'.repl.toggle({}, 'vsplit')<CR><C-w>l",
					mode = "n",
					desc = "Debug toggle REPL",
				},
				{ lhs = "<Leader>dro", rhs = ":lua require('dap').repl.open()<CR>", mode = "n", desc =  "Debug open REPL" },
				{ lhs = "<Leader>drl", rhs = ":lua require('dap').repl.run_last()<CR>", mode = "n", desc =  "Debug run last REPL" },

				{
					lhs = "<leader>de",
					rhs = ":lua require'dap'.set_exception_breakpoints({'all'})<CR>",
					mode = "n",
					desc = "Debug execution breakpoint",
				},
				{
					lhs = "<Leader>dbc",
					rhs = ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
					mode = "n",
					desc = "Debug condition breakpoint",
				},
				{
					lhs = "<Leader>dbm",
					rhs = ":lua require('dap').set_breakpoint({ nil, nil, vim.fn.input('Log point message: ') })<CR>",
					mode = "n",
					desc = "Debug breakpoint with message",
				},
			},
			after = function(_)
				local dap = require("dap")
				local h = require("utils.dap_helpers")
				local last_picked_dll = nil

				-- ADAPTERS (CoreCLR)
				dap.adapters.coreclr = {
					type = "executable",
					command = h.resolve_first_existing({
						vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
						"netcoredbg",
					}),
					args = { "--interpreter=vscode" },
				}

				-- DOTNET LOGIC
				local function coreclr_build_then_pick()
					return {
						type = "coreclr",
						request = "launch",
						cwd = function()
							if not last_picked_dll then
								return h.detect_project_root()
							end
							return last_picked_dll:match("^(.*)[/\\]bin[/\\]")
								or vim.fn.fnamemodify(last_picked_dll, ":h")
						end,
						program = function()
							local root, file = h.detect_project_root()
							local co = coroutine.running()
							vim.fn.jobstart({ "dotnet", "build", file or root }, {
								on_exit = function(_, rc)
									if rc ~= 0 then
										coroutine.resume(co, nil)
										return
									end
									local dlls = h.list_candidate_dlls(root)
									if
										not h.pick_with_fzf(dlls, "Select DLL", function(c)
											last_picked_dll = c
											coroutine.resume(co, c)
										end)
									then
										vim.ui.select(dlls, {}, function(c)
											last_picked_dll = c
											coroutine.resume(co, c)
										end)
									end
								end,
							})
							return coroutine.yield()
						end,
					}
				end

				for _, lang in ipairs({ "cs", "csharp" }) do
					dap.configurations[lang] = { coreclr_build_then_pick() }
				end

				-- 💥 THE TRIPWIRES: When Neovim reads these lines, it intercepts the require()
				-- and instantly wakes up the adapters we put to sleep at the top!
				if vim.g.enablePython then
					require("dap-python").setup(vim.g.python3_host_prog)
				end
				require("dap-go").setup({})

				-- RUST (CodeLLDB)
				dap.adapters.codelldb = { type = "server", host = "127.0.0.1", port = 13000 }
				dap.configurations.rust = {
					{
						name = "rustacean",
						type = "codelldb",
						request = "launch",
						program = function()
							local co = coroutine.running()
							vim.ui.input(
								{ prompt = "Executable: ", default = vim.fn.getcwd() .. "/target/debug/" },
								function(s)
									coroutine.resume(co, s)
								end
							)
							return coroutine.yield()
						end,
					},
				}

				-- LUA
				dap.adapters.nlua = function(callback, config)
					callback({ type = "server", host = config.host or "127.0.0.1", port = 5677 })
				end

				-- We tell DAP how to map custom debug types to Neovim filetypes.
				require("dap.ext.vscode").type_to_filetypes = {
					coreclr = { "cs", "csharp" },
					["pwa-node"] = js_langs,
				}

				-- dap-view: lazy-load by triggering require on session events
				dap.listeners.before.attach.dapui_config = function()
					require("dap-view").open()
				end
				dap.listeners.before.launch.dapui_config = function()
					require("dap-view").open()
				end
				dap.listeners.before.event_terminated.dapui_config = function()
					require("dap-view").close()
				end
				dap.listeners.before.event_exited.dapui_config = function()
					require("dap-view").close()
				end
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

-- -- dap debugging
-- wk.add({
-- 	{ "<leader>d", group = "Dap" },
-- })
