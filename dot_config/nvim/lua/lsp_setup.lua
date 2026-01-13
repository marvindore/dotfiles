-- lua/lsp_ui.lua
-- LSP UI, keymaps, and global capabilities module for Neovim v0.11+

local M = {}

-- Register the LspAttach autocmd once, early in startup.
function M.setup_lsp_attach()
	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local bufnr = args.buf
			local client = vim.lsp.get_client_by_id(args.data.client_id)

			-- Local helper to define buffer-local LSP keymaps with a standard prefix
			local function map(mode, keys, func, desc)
				vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
			end

			-- Try loading fzf-lua lazily; skip pickers if it isn’t available
			local has_fzf, fzf = pcall(require, "fzf-lua")

			local picker_definition = has_fzf and function()
				fzf.lsp_definitions()
			end or vim.lsp.buf.definition
			local picker_references = has_fzf and function()
				fzf.lsp_references()
			end or vim.lsp.buf.references
			local picker_implementations = has_fzf and function()
				fzf.lsp_implementations()
			end or vim.lsp.buf.implementation
			local picker_declaration = has_fzf and function()
				fzf.lsp_declarations()
			end or vim.lsp.buf.declaration
			local picker_typedefs = has_fzf and function()
				fzf.lsp_typedefs()
			end or vim.lsp.buf.type_definition
			local picker_symbols = has_fzf and function()
				fzf.lsp_document_symbols()
			end or function()
				vim.lsp.buf.document_symbol()
			end

			-- Core LSP keymaps (buffer-local)
			map("n", "gd", picker_definition, "Go To Definition")
			map("n", "gr", picker_references, "References")
			map("n", "gi", picker_implementations, "Go To Implementation")
			map("n", "gs", picker_symbols, "Document Symbols")
			map("n", "K", function()
				vim.lsp.buf.hover({ border = "rounded" })
			end, "Hover")
			map("n", "gt", picker_typedefs, "Go To Type Definition")
			map("n", "rn", vim.lsp.buf.rename, "Rename")
			map("n", "gc", vim.lsp.buf.code_action, "Code Action")
			map("n", "gD", picker_declaration, "Go To Declaration")

			-- Workspace & diagnostics
			map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Workspace Add")
			map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Workspace Remove")
			map("n", "[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
			map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
			map("n", "<LocalLeader>do", vim.diagnostic.open_float, "Diagnostics Float")
			map("n", "<leader>q", vim.diagnostic.setloclist, "Diagnostics to Loclist")

			-- Toggle inlay hints (Neovim v0.11 API)
			map("n", "<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, "Toggle Inlay Hints")

			-- Toggle diagnostics visibility (session-global flag)
			local function toggle_diagnostics()
				if vim.g.diagnostics_visible then
					vim.g.diagnostics_visible = false
					vim.diagnostic.enable(false)
				else
					vim.g.diagnostics_visible = true
					vim.diagnostic.enable()
				end
			end
			map("n", "<leader>dh", toggle_diagnostics, "Toggle Diagnostics")

			-- --- Server-specific settings/keymaps -----------------------------------
			if client then
				if client.name == "jdtls" then
					map("n", "<leader>dvc", function()
						require("jdtls").test_class()
					end, "Java Test Class")
					map("n", "<leader>dvm", function()
						require("jdtls").test_nearest_method()
					end, "Java Test Nearest Method")
				elseif client.name == "ts_ls" or client.name == "vtsls" then
					-- Example: turn off formatting to let a formatter handle it
					client.server_capabilities.documentFormattingProvider = false
				elseif client.name == "roslyn" then
					-- Group names with which-key, if present
					local has_wk, wk = pcall(require, "which-key")
					if has_wk then
						wk.add({
							{ "<leader>i", group = "IDE" },
							{ "<leader>it", group = "IDE Test" },
							{ "<leader>ir", group = "IDE Run" },
							{ "<leader>is", group = "IDE Secrets" },
							{ "<leader>ib", group = "IDE Build" },
							{ "<leader>ic", group = "IDE Clean" },
							{ "<leader>id", group = "IDE MSC" },
						})
					end

					-- Easy .NET helpers
					map("n", "<leader>idd", function()
						coroutine.wrap(function()
							require("easy-dotnet").debug_default()
						end)()
					end, "Dotnet Debug")
					-- Easy .NET helpers
					-- Debug: requires coroutine context (solution parsing)
					map("n", "<leader>idd", function()
						coroutine.wrap(function()
							require("easy-dotnet").debug_default()
						end)()
					end, "Dotnet Debug (Default)")

					map("n", "<leader>idp", function()
						coroutine.wrap(function()
							require("easy-dotnet").debug_profile_default()
						end)()
					end, "Dotnet Debug Profile (Default)")

					-- Tests
					-- NOTE: There is no `test_project()` in the public API. Use `test()` (picker) or `test_default()`.
					map("n", "<leader>itp", function()
						require("easy-dotnet").test() -- picker for project/tests
					end, "Dotnet Test (Picker)")

					map("n", "<leader>itd", function()
						require("easy-dotnet").test_default()
					end, "Dotnet Test (Default)")

					map("n", "<leader>its", function()
						require("easy-dotnet").test_solution()
					end, "Dotnet Test Solution")

					-- Run
					map("n", "<leader>irr", function()
						require("easy-dotnet").run()
					end, "Dotnet Run")

					map("n", "<leader>irp", function()
						require("easy-dotnet").run_profile()
					end, "Dotnet Run Profile")

					map("n", "<leader>irP", function()
						require("easy-dotnet").run_profile_default()
					end, "Dotnet Run Profile Default")

					map("n", "<leader>ird", function()
						require("easy-dotnet").run_default()
					end, "Dotnet Run Default")

					-- Restore
					map("n", "<leader>ire", function()
						require("easy-dotnet").restore()
					end, "Dotnet Restore")

					-- Secrets
					map("n", "<leader>ise", function()
						require("easy-dotnet").secrets()
					end, "Dotnet Secrets")

					-- Build
					map("n", "<leader>ibb", function()
						require("easy-dotnet").build()
					end, "Dotnet Build")

					map("n", "<leader>ibd", function()
						require("easy-dotnet").build_default()
					end, "Dotnet Build Default")

					map("n", "<leader>ibs", function()
						require("easy-dotnet").build_solution()
					end, "Dotnet Build Solution")

					map("n", "<leader>ibq", function()
						require("easy-dotnet").build_quickfix()
					end, "Dotnet Build Quickfix")

					map("n", "<leader>ibQ", function()
						require("easy-dotnet").build_default_quickfix()
					end, "Dotnet Build Default Quickfix")

					-- Clean (acts on solution/selection; rename description to avoid confusion)
					map("n", "<leader>icp", function()
						require("easy-dotnet").clean()
					end, "Dotnet Clean")
				end
			end
			-- -----------------------------------------------------------------------
		end,
	})
end

-- Optionally set global capabilities via vim.lsp.config("*", ...)
function M.setup_global_capabilities()
	local success, blink = pcall(require, "blink.cmp")
	local capabilities = {
		workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
	}
	if success then
		vim.lsp.config("*", {
			capabilities = blink.get_lsp_capabilities(capabilities),
		})
	end
end

-- Enable servers (register FileType handlers).
-- Accepts booleans (guards) for conditional enablement.
function M.enable_servers(opts)
	opts = opts or {}
	local g = vim.g

	vim.lsp.enable("lua_ls")
	vim.lsp.enable({ "bashls", "yamlls", "dockerls", "jsonls", "lemminx" })

	if opts.enable_js ~= nil and opts.enable_js or g.enableJavascript then
		vim.lsp.enable({ "angularls", "astro", "vtsls" })
	end

	if opts.enable_sql ~= nil and opts.enable_sql or g.enableSql then
		vim.lsp.enable("sql")
	end

	if opts.enable_go ~= nil and opts.enable_go or g.enableGo then
		vim.lsp.enable("go")
	end

	if opts.enable_pwsh ~= nil and opts.enable_pwsh or g.isWindowsOs then
		vim.lsp.enable("pwsh")
	end

	if opts.enable_rust ~= nil and opts.enable_rust or g.enableRust then
		vim.lsp.enable("rust")
	end
end

return M
