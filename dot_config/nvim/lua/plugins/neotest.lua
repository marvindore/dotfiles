-- ==========================================
-- Neotest: core + adapters (with lze bridge)
-- - Eager-load non-Lua deps (plenary, nio, FixCursorHold, vim-test)
-- - Lazy-load adapters on first require()
-- - Keymaps load core on first use
-- - Branch-safe Treesitter parser check (no legacy parsers.has_parser)
-- ==========================================

-- 1) Eager, non-Lua helpers + required deps
-- NOTE: During init.lua, vim.pack.add() defaults to load=false (:packadd!).
-- We need plugin/ files for vim-test, so force a real load here. [1](https://neovim.io/doc/user/pack.html)
vim.pack.add({
	-- Required by Neotest core
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-neotest/nvim-nio",

	-- Strongly recommended in Neotest docs (CursorHold/updatetime tweaks)
	"https://github.com/antoinemadec/FixCursorHold.nvim",

	-- Needed if you use the neotest-vim-test adapter
	"https://github.com/vim-test/vim-test",
}, {
	load = true, -- <— critical fix so vim-test's plugin/ files are sourced at startup
})

-- -------- Branch-safe Treesitter parser check (main + legacy) --------
local function ts_parser_installed(lang)
	-- Prefer the new, branch=main way: inspect runtimepath for parser files
	local so = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", false)
	local wasm = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".wasm", false)
	if #so > 0 or #wasm > 0 then
		return true
	end

	-- Fallback to legacy module if present (branch=master)
	local ok_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
	if ok_parsers and type(parsers.has_parser) == "function" then
		return parsers.has_parser(lang)
	end

	return false
end
-- --------------------------------------------------------------------

-- 2) Adapters + core (lazy via lze)
vim.pack.add({
	-- Adapters (wake on first `require("<name>")`)
	{ src = "https://github.com/nvim-neotest/neotest-python", data = { on_require = { "neotest-python" } } },
	{ src = "https://github.com/nvim-neotest/neotest-plenary", data = { on_require = { "neotest-plenary" } } },
	{ src = "https://github.com/nvim-neotest/neotest-go", data = { on_require = { "neotest-go" } } },
	{ src = "https://github.com/haydenmeade/neotest-jest", data = { on_require = { "neotest-jest" } } },
	{ src = "https://github.com/nsidorenco/neotest-vstest", data = { on_require = { "neotest-vstest" } } },
	{ src = "https://github.com/stevanmilic/neotest-scala", data = { on_require = { "neotest-scala" } } },
	{ src = "https://github.com/rouge8/neotest-rust", data = { on_require = { "neotest-rust" } } },
	{ src = "https://github.com/nvim-neotest/neotest-vim-test", data = { on_require = { "neotest-vim-test" } } },

	-- Core Neotest
	{
		src = "https://github.com/nvim-neotest/neotest",
		data = {
			-- Keymaps that wake Neotest and call its API
			keys = {
				-- Summary / UI
				{
					lhs = "<leader>tt",
					rhs = "<cmd>lua require('neotest').summary.toggle()<CR>",
					mode = { "n" },
					desc = "Neotest: Toggle summary",
				},
				{
					lhs = "<leader>to",
					rhs = "<cmd>lua require('neotest').output.open({ enter = true, last_run = true })<CR>",
					mode = "n",
					desc = "Neotest: Open output (last run)",
				},
				{
					lhs = "<leader>tpp",
					rhs = "<cmd>lua require('neotest').output_panel.toggle()<CR>",
					mode = "n",
					desc = "Neotest: Toggle output panel",
				},
				-- Built-in user command supports `clear`
				{
					lhs = "<leader>tpc",
					rhs = ":Neotest output-panel clear<CR>",
					mode = "n",
					desc = "Neotest: Clear output panel",
				},

				-- Run / Debug
				{
					lhs = "<leader>tr",
					rhs = "<cmd>lua require('neotest').run.run()<CR>",
					mode = "n",
					desc = "Neotest: Run nearest",
				},
				{
					lhs = "<leader>tf",
					rhs = "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<CR>",
					mode = "n",
					desc = "Neotest: Run file",
				},
				{
					lhs = "<leader>td",
					rhs = "<cmd>lua require('neotest').run.run({ strategy = 'dap' })<CR>",
					mode = "n",
					desc = "Neotest: Debug nearest (DAP)",
				},
				{
					lhs = "<leader>ts",
					rhs = "<cmd>lua require('neotest').run.stop()<CR>",
					mode = "n",
					desc = "Neotest: Stop",
				},
				{
					lhs = "<leader>ta",
					rhs = "<cmd>lua require('neotest').run.attach()<CR>",
					mode = "n",
					desc = "Neotest: Attach",
				},

				-- Watch
				{
					lhs = "<leader>tw",
					rhs = "<cmd>lua require('neotest').watch.toggle(vim.fn.expand('%'))<CR>",
					mode = "n",
					desc = "Neotest: Toggle watch (file)",
				},

				-- Diagnostics / Info helpers
				{
					lhs = "<leader>tI",
					rhs = "<cmd>NeotestInfo<CR>",
					mode = "n",
					desc = "Neotest: Info",
				},
				{
					lhs = "<leader>tL",
					rhs = "<cmd>NeotestLogToggle<CR>",
					mode = "n",
					desc = "Neotest: Toggle DEBUG logs",
				},
			},

			after = function(_)
				----------------------------------------------------------------------
				-- Robust Python interpreter selector (venv -> project -> mise -> python3)
				----------------------------------------------------------------------
				local function pick_python()
					local venv = os.getenv("VIRTUAL_ENV")
					if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
						return venv .. "/bin/python"
					end
					local cwd = vim.fn.getcwd()
					if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
						return cwd .. "/.venv/bin/python"
					elseif vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
						return cwd .. "/venv/bin/python"
					end
					local home = vim.g.homeDir or vim.loop.os_homedir()
					local mise_py = home .. "/.local/share/mise/shims/python3"
					if vim.fn.executable(mise_py) == 1 then
						return mise_py
					end
					return "python3"
				end

				----------------------------------------------------------------------
				-- Optional: warn if TS python parser missing (affects discovery)
				----------------------------------------------------------------------
				local function warn_if_ts_python_missing()
					if not ts_parser_installed("python") then
						vim.schedule(function()
							vim.notify(
								"Neotest: Treesitter 'python' parser not installed; test discovery may be limited. Run :TSInstall python",
								vim.log.levels.WARN
							)
						end)
					end
				end
				warn_if_ts_python_missing()

				----------------------------------------------------------------------
				-- Neotest setup
				-- NOTE: It's safe to pass only the fields you need; Neotest merges defaults.
				----------------------------------------------------------------------
				local ok_neotest, neotest = pcall(require, "neotest")
				if not ok_neotest then
					vim.notify("neotest not found", vim.log.levels.ERROR)
					return
				end

				---@diagnostic disable-next-line: missing-fields
				neotest.setup({
					log_level = vim.log.levels.WARN,

					status = { enabled = true, signs = true, virtual_text = false },
					output = { enabled = true, open_on_run = "short" },
					output_panel = { enabled = true, open = "botright split | resize 15" },

					adapters = {
						-- Python (pytest/unittest)
						require("neotest-python")({
							dap = { justMyCode = false },
							python = pick_python,
							pytest_discover_instances = false, -- experimental
						}),

						-- Rust
						require("neotest-rust")({}),

						-- .NET (vstest)
						require("neotest-vstest")({}),

						-- Scala
						require("neotest-scala")({}),

						-- Jest
						require("neotest-jest")({
							-- Valid adapter options: jestCommand, jestArguments, jestConfigFile, env, cwd, isTestFile
							jestCommand = "npm test --",
							jestConfigFile = "custom.jest.config.ts",
							env = { CI = true },
							cwd = function()
								return vim.fn.getcwd()
							end,
							-- jestArguments = function(defaultArgs, ctx) return defaultArgs end,
						}),

						-- Go
						require("neotest-go")({}),

						-- Plenary (Lua tests)
						require("neotest-plenary")({}),

						-- vim-test catch-all (avoid duplicates with explicit adapters)
						require("neotest-vim-test")({
							ignore_file_types = { "python", "vim", "lua", "cs", "rust", "scala" },
						}),
					},
				})

				----------------------------------------------------------------------
				-- Helper commands
				----------------------------------------------------------------------
				vim.api.nvim_create_user_command("NeotestInfo", function()
					local python = pick_python()
					local msgs = {
						"Neotest Info:",
						"  python: " .. python .. " (exec=" .. vim.fn.executable(python) .. ")",
						"  ts python parser: " .. (ts_parser_installed("python") and "yes" or "no"),
					}
					local loaded = {
						neotest = package.loaded["neotest"] ~= nil,
						python = package.loaded["neotest-python"] ~= nil,
					}
					table.insert(
						msgs,
						("  neotest loaded: %s  |  adapter (python) loaded: %s"):format(
							tostring(loaded.neotest),
							tostring(loaded.python)
						)
					)
					vim.notify(table.concat(msgs, "\n"), vim.log.levels.INFO)
				end, {})

				vim.api.nvim_create_user_command("NeotestLogToggle", function()
					local cfg = require("neotest.config")
					local current = cfg.log_level
					local new = current == vim.log.levels.DEBUG and vim.log.levels.WARN or vim.log.levels.DEBUG
					cfg.log_level = new
					vim.notify("Neotest log_level: " .. (new == vim.log.levels.DEBUG and "DEBUG" or "WARN"))
				end, {})
			end,
		},
	},
}, {
	-- lze bridge
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
