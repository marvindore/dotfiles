-- Only load this entire file if C# is enabled AND we're in a .NET context
if not vim.g.enableCsharp then
  return
end

-- Decide based on the *current buffer* or the *initial CWD* Neovim started in.
local function in_dotnet_context_startup()
  local buf = 0
  local ft = vim.bo[buf].filetype

  -- If we already have a C#-related buffer, that's enough.
  if ft == "cs" or ft == "razor" or ft == "cshtml" or ft == "csproj" or ft == "fsproj" then
    return true
  end

  -- If Neovim was opened without a file (or with a non-C# file),
  -- check the directory Neovim was started in (CWD) for a .NET project/solution file.
  local cwd = vim.loop.cwd()
  local found = vim.fs.find(function(n, _)
    return n:match("%.sln$") or n:match("%.csproj$") or n:match("%.fsproj$")
  end, { path = cwd, limit = 1 }) -- note: CWD only, no upward search

  return #found > 0
end

if not in_dotnet_context_startup() then
  return
end

vim.pack.add({
	-- Dependencies
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/folke/snacks.nvim",

	-- The main easy-dotnet plugin wrapped for lze
	{
		src = "https://github.com/GustavEikaas/easy-dotnet.nvim",
		data = {
			-- Lazy load on C# related filetypes
			ft = { "cs", "razor", "csproj", "fsproj","sln" },

			-- Lazy load if you type the custom command
			keys = { 
					-- -- Group names with which-key, if present
					-- local has_wk, wk = pcall(require, "which-key")
					-- if has_wk then
					-- 	wk.add({
					-- 		{ "<leader>i", group = "IDE" },
					-- 		{ "<leader>it", group = "IDE Test" },
					-- 		{ "<leader>ir", group = "IDE Run" },
					-- 		{ "<leader>is", group = "IDE Secrets" },
					-- 		{ "<leader>ib", group = "IDE Build" },
					-- 		{ "<leader>ic", group = "IDE Clean" },
					-- 		{ "<leader>id", group = "IDE MSC" },
					-- 	})
					-- end
					-- -- Easy .NET helpers
					-- -- Debug: requires coroutine context (solution parsing)
          { mode = "n", lhs = "<leader>idd", rhs =function()
						coroutine.wrap(function()
							require("easy-dotnet").debug_default()
						end)()
					end, desc = "Dotnet Debug (Default)" },

          { mode ="n", lhs = "<leader>idp", rhs = function()
						coroutine.wrap(function()
							require("easy-dotnet").debug_profile_default()
						end)()
					end, desc = "Dotnet Debug Profile (Default)" },

					-- Tests
					-- NOTE: There is no `test_project()` in the public API. Use `test()` (picker) or `test_default()`.
          { mode ="n", lhs = "<leader>itp", rhs = function()
						require("easy-dotnet").test() -- picker for project/tests
					end, "Dotnet Test (Picker)" },

          { mode ="n", lhs = "<leader>itd", rhs = function()
						require("easy-dotnet").test_default()
					end, desc = "Dotnet Test (Default)" },

          { mode ="n", lhs = "<leader>its", rhs = function()
						require("easy-dotnet").test_solution()
					end, desc = "Dotnet Test Solution" },

					-- Run
          { mode = {"n"}, lhs = "<leader>irr", rhs = function()
						require("easy-dotnet").run()
					end, desc = "Dotnet Run" },

          { mode ="n", lhs = "<leader>irp", rhs = function()
						require("easy-dotnet").run_profile()
					end, desc = "Dotnet Run Profile" },

          { mode ="n", lhs = "<leader>irP", rhs = function()
						require("easy-dotnet").run_profile_default()
					end, desc = "Dotnet Run Profile Default" },

          { mode ="n", lhs = "<leader>ird", rhs = function()
						require("easy-dotnet").run_default()
					end, desc = "Dotnet Run Default" },

					-- Restore
          { mode = "n", lhs = "<leader>ire", rhs = function()
						require("easy-dotnet").restore()
					end, desc = "Dotnet Restore" },

					-- Secrets
          { mode = "n", lhs = "<leader>ise", rhs = function()
						require("easy-dotnet").secrets()
					end, desc = "Dotnet Secrets" },

					-- Build
          { mode = "n", lhs = "<leader>ibb", rhs = function()
						require("easy-dotnet").build()
					end, desc = "Dotnet Build" },

          { mode = "n", lhs = "<leader>ibd", rhs = function()
						require("easy-dotnet").build_default()
					end, desc = "Dotnet Build Default" },

          { mode = "n", lhs = "<leader>ibs", rhs = function()
						require("easy-dotnet").build_solution()
					end, desc = "Dotnet Build Solution" },

          { mode = "n", lhs = "<leader>ibq", rhs = function()
						require("easy-dotnet").build_quickfix()
					end, desc = "Dotnet Build Quickfix" },

          { mode = "n", lhs = "<leader>ibQ", rhs = function()
						require("easy-dotnet").build_default_quickfix()
					end, desc = "Dotnet Build Default Quickfix" },

					-- Clean (acts on solution/selection; rename description to avoid confusion)
          { mode = "n", lhs = "<leader>icp", rhs = function()
						require("easy-dotnet").clean()
					end, desc = "Dotnet Clean" },
			},

			after = function(_)
				local dotnet = require("easy-dotnet")

				local function get_secret_path(secret_guid)
					local home = vim.fn.expand("~")
					if require("easy-dotnet.extensions").isWindows() then
						return home .. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\" .. secret_guid .. "\\secrets.json"
					else
						return home .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
					end
				end

				dotnet.setup({
					lsp = {
						enabled = true,
						roslynator_enabled = true,
						analyzer_assemblies = {},
						config = {},
					},
					debugger = {
						bin_path = nil,
						apply_value_converters = true,
						auto_register_dap = true,
						mappings = {
							open_variable_viewer = { lhs = "T", desc = "open variable viewer" },
						},
					},
					test_runner = {
						viewmode = "float",
						vsplit_width = nil,
						vsplit_pos = nil,
						enable_buffer_test_execution = true,
						noBuild = true,
						icons = {
							passed = "",
							skipped = "",
							failed = "",
							success = "",
							reload = "",
							test = "",
							sln = "󰘐",
							project = "󰘐",
							dir = "",
							package = "",
						},
						mappings = {
							run_test_from_buffer = { lhs = "<leader>r", desc = "run test from buffer" },
							run_all_tests_from_buffer = { lhs = "<leader>t", desc = "run all tests from buffer" },
							peek_stack_trace_from_buffer = { lhs = "<leader>p", desc = "peek stack trace from buffer" },
							filter_failed_tests = { lhs = "<leader>fe", desc = "filter failed tests" },
							debug_test = { lhs = "<leader>d", desc = "debug test" },
							go_to_file = { lhs = "g", desc = "go to file" },
							run_all = { lhs = "<leader>R", desc = "run all tests" },
							run = { lhs = "<leader>r", desc = "run test" },
							peek_stacktrace = { lhs = "<leader>p", desc = "peek stacktrace of failed test" },
							expand = { lhs = "o", desc = "expand" },
							expand_node = { lhs = "E", desc = "expand node" },
							expand_all = { lhs = "-", desc = "expand all" },
							collapse_all = { lhs = "W", desc = "collapse all" },
							close = { lhs = "q", desc = "close testrunner" },
							refresh_testrunner = { lhs = "<C-r>", desc = "refresh testrunner" },
						},
						additional_args = {},
					},
					new = {
						project = { prefix = "sln" },
					},
					terminal = function(path, action, args)
						args = args or ""
						local commands = {
							run = function()
								return string.format("dotnet run --project %s %s", path, args)
							end,
							test = function()
								return string.format("dotnet test %s %s", path, args)
							end,
							restore = function()
								return string.format("dotnet restore %s %s", path, args)
							end,
							build = function()
								return string.format("dotnet build %s %s", path, args)
							end,
							watch = function()
								return string.format("dotnet watch --project %s %s", path, args)
							end,
						}
						local command = commands[action]()
						if require("easy-dotnet.extensions").isWindows() == true then
							command = command .. "\r"
						end
						vim.cmd("vsplit")
						vim.cmd("term " .. command)
					end,
					secrets = { path = get_secret_path },
					csproj_mappings = true,
					fsproj_mappings = true,
					auto_bootstrap_namespace = {
						type = "block_scoped",
						enabled = true,
						use_clipboard_json = {
							behavior = "prompt",
							register = "+",
						},
					},
					server = { log_level = nil },
					picker = "snacks",
					background_scanning = true,
					notifications = {
						handler = function(start_event)
							local spinner = require("easy-dotnet.ui-modules.spinner").new()
							spinner:start_spinner(start_event.job.name)
							return function(finished_event)
								spinner:stop_spinner(finished_event.result.msg, finished_event.result.level)
							end
						end,
					},
					diagnostics = {
						default_severity = "error",
						setqflist = false,
					},
				})

				vim.api.nvim_create_user_command("Secrets", function()
					dotnet.secrets()
				end, {})
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
