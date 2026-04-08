-- lua/lsp_setup.lua
-- Optimized LSP configuration for Neovim v0.11+
local M = {}

-- DEFERRED HELPER: Only runs when a JS/TS file is opened
local function detect_angular()
	local root = vim.fn.getcwd()
	local angular_files = { root .. "/angular.json", root .. "/nx.json" }

	for _, file in ipairs(angular_files) do
		if vim.fn.filereadable(file) == 1 then
			vim.lsp.enable("angularls")
			return
		end
	end

	-- fallback to package.json scanning
	local pkg_json = root .. "/package.json"
	if vim.fn.filereadable(pkg_json) == 1 then
		local f = io.open(pkg_json, "r")
		if f then
			local content = f:read("*all"):lower()
			f:close()
			if content:find("angular", 1, true) then
				vim.lsp.enable("angularls")
			end
		end
	end
end

function M.setup_lsp_attach()
	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local bufnr = args.buf
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if not client then
				return
			end

			local function map(mode, keys, func, desc)
				vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
			end

			-- Helper to use fzf-lua pickers if available
			local has_fzf, fzf = pcall(require, "fzf-lua")

			map("n", "gd", has_fzf and fzf.lsp_definitions or vim.lsp.buf.definition, "Go To Definition")
			map("n", "gr", has_fzf and fzf.lsp_references or vim.lsp.buf.references, "References")
			map("n", "gi", has_fzf and fzf.lsp_implementations or vim.lsp.buf.implementation, "Go To Implementation")
			map("n", "gs", has_fzf and fzf.lsp_document_symbols or vim.lsp.buf.document_symbol, "Document Symbols")
			map("n", "K", function()
				vim.lsp.buf.hover({ border = "rounded" })
			end, "Hover")
			map("n", "gt", has_fzf and fzf.lsp_typedefs or vim.lsp.buf.type_definition, "Type Definition")
			map("n", "rn", vim.lsp.buf.rename, "Rename")
			map("n", "gc", vim.lsp.buf.code_action, "Code Action")
			map("n", "gD", has_fzf and fzf.lsp_declarations or vim.lsp.buf.declaration, "Go To Declaration")

			-- Diagnostics & Hints
			map("n", "[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
			map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
			map("n", "<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, "Toggle Inlay Hints")

			-- Server-specific logic
			if client.name == "jdtls" then
				map("n", "<leader>dvc", require("jdtls").test_class, "Java Test Class")
				map("n", "<leader>dvm", require("jdtls").test_nearest_method, "Java Test Method")
			end
		end,
	})
end

function M.setup_global_capabilities()
	-- Use vim.schedule to ensure blink is ready without blocking startup
	vim.schedule(function()
		local success, blink = pcall(require, "blink.cmp")
		if success then
			vim.lsp.config("*", {
				capabilities = blink.get_lsp_capabilities({
					workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
				}),
			})
		end
	end)
end

function M.enable_servers(opts)
	opts = opts or {}
	local g = vim.g

	-- Inject Mason PATH (Corrected separator for cross-platform)
	local sep = vim.fn.has("win32") == 1 and ";" or ":"
	vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. sep .. vim.env.PATH

	-- 1. Enable generic servers immediately (Very fast)
	vim.lsp.enable({ "lua_ls", "bashls", "harper_ls", "yamlls", "dockerls", "jsonls", "lemminx", "marksman" })

	-- 2. Setup Autocmds for Heavy/Context-Dependent servers
	-- This moves the "IF" logic from Startup to File Open

	-- JavaScript / TypeScript / Angular
	if opts.enable_js or g.enableJavascript then
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "javascript", "typescript", "typescriptreact", "javascriptreact" },
			callback = function()
				vim.lsp.enable({ "vtsls", "astro" })
				detect_angular() -- This now runs ONLY when you open a JS file
				return true -- Only run detection once per session
			end,
		})
	end

	-- Python
	if opts.enable_python or g.enablePython then
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "python",
			callback = function()
				vim.lsp.enable({ "pyright", "ruff" })
				return true
			end,
		})
	end

	-- Rust
	if opts.enable_rust or g.enableRust then
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "rust",
			callback = function()
				vim.lsp.enable("rust_analyzer")
				return true
			end,
		})
	end

	-- Simple Toggles (Fast enough to keep here if desired)
	if g.enableGo then
		vim.lsp.enable("gopls")
	end
	if g.enableSql then
		vim.lsp.enable("sqls")
	end
	if g.isWindowsOs then
		vim.lsp.enable("pwsh")
	end
end

return M
