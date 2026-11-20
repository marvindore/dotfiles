-- lua/lsp_setup.lua
-- Optimized LSP configuration for Neovim v0.11+
local M = {}
local warned_missing_ty = {}
local warned_missing_go = {}

-- fzf-lua picker when available, else the vim.lsp.buf fallback.
local function has_fzf_lua()
	local ok, fzf = pcall(require, "fzf-lua")
	return ok and fzf or nil
end

local function hover()
	vim.lsp.buf.hover({ border = "rounded" })
end

local function toggle_inlay_hints()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

-- { lhs, fzf-lua function name, vim.lsp.buf fallback, desc }
local PICKERS = {
	{ "gd", "lsp_definitions", vim.lsp.buf.definition, "Go To Definition" },
	{ "gD", "lsp_declarations", vim.lsp.buf.declaration, "Go To Declaration" },
	{ "<leader>lr", "lsp_references", vim.lsp.buf.references, "References" },
	{ "<leader>li", "lsp_implementations", vim.lsp.buf.implementation, "Implementation" },
	{ "<leader>lt", "lsp_typedefs", vim.lsp.buf.type_definition, "Type Definition" },
	{ "<leader>ls", "lsp_document_symbols", vim.lsp.buf.document_symbol, "Document Symbols" },
	{ "<leader>lS", "lsp_live_workspace_symbols", vim.lsp.buf.workspace_symbol, "Workspace Symbols" },
	{ "<leader>la", "lsp_code_actions", vim.lsp.buf.code_action, "Code Action", mode = { "n", "x" } },
	-- gr* defaults: use the same fzf-lua pickers
	{ "grr", "lsp_references", vim.lsp.buf.references, "References" },
	{ "gri", "lsp_implementations", vim.lsp.buf.implementation, "Implementation" },
	{ "grt", "lsp_typedefs", vim.lsp.buf.type_definition, "Type Definition" },
	{ "gO", "lsp_document_symbols", vim.lsp.buf.document_symbol, "Document Symbols" },
}

---@param fzf table|nil
---@return { lhs: string, rhs: function, desc: string, mode: string|string[]|nil }[]
local function lsp_maps(fzf)
	local maps = {
		{ lhs = "K", rhs = hover, desc = "Hover" },
		{ lhs = "<leader>ln", rhs = vim.lsp.buf.rename, desc = "Rename (name)" },
		{ lhs = "<leader>lh", rhs = toggle_inlay_hints, desc = "Toggle Inlay Hints" },
	}
	for _, p in ipairs(PICKERS) do
		local lhs, picker, fallback, desc = p[1], p[2], p[3], p[4]
		local rhs = fzf and fzf[picker] or fallback
		table.insert(maps, { lhs = lhs, rhs = rhs, desc = desc, mode = p.mode })
	end
	return maps
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

			-- gd/gD/K plus the <leader>l (LSP) group. The Neovim 0.11+ defaults
			-- (grn, gra, grr, gri, grt, gO, [d, ]d) stay as aliases.
			for _, m in ipairs(lsp_maps(has_fzf_lua())) do
				map(m.mode or "n", m.lhs, m.rhs, m.desc)
			end

			-- Server-specific logic
			if client.name == "jdtls" then
				map("n", "<leader>dvc", require("jdtls").test_class, "Java Test Class")
				map("n", "<leader>dvm", require("jdtls").test_nearest_method, "Java Test Method")
			end
		end,
	})
end

function M.setup_global_capabilities()
	-- blink.cmp is loaded eagerly (plugins/blink.lua), so set this before any server starts.
	local success, blink = pcall(require, "blink.cmp")
	if success then
		vim.lsp.config("*", {
			capabilities = blink.get_lsp_capabilities({
				workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
			}),
		})
	end
end

function M.enable_servers(opts)
	opts = opts or {}
	local g = vim.g

	-- Inject Mason PATH (Corrected separator for cross-platform)
	local sep = vim.fn.has("win32") == 1 and ";" or ":"
	vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. sep .. vim.env.PATH

	-- 1. Enable generic servers immediately (Very fast)
	-- These names now map directly to files in your lsp/ directory (e.g. lsp/lua_ls.lua)
	vim.lsp.enable({ "lua_ls", "bashls", "harper_ls", "yamlls", "dockerls", "jsonls", "lemminx", "marksman" })

	-- 2. Setup Autocmds for Heavy/Context-Dependent servers
	-- This moves the "IF" logic from Startup to File Open

	-- JavaScript / TypeScript: tsc (TS 7) by default, vtsls for Angular/Astro/tsserver plugins.
	-- Each server's root_dir asks utils/ts_server.lua if it must attach in that project.
	if opts.enable_js or g.enableJavascript then
		vim.lsp.enable({ "tsc", "vtsls", "angularls", "astro", "eslint" })
	end

	-- Python
	if opts.enable_python or g.enablePython then
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "python",
			callback = function()
				local root = vim.fs.root(0, {
					"ty.toml",
					"pyproject.toml",
					"setup.py",
					"setup.cfg",
					"requirements.txt",
					"Pipfile",
					".git",
				}) or vim.fn.getcwd()
				local project_ty = root .. "/.venv/bin/ty"
				local has_project_ty = vim.fn.executable(project_ty) == 1
				local has_global_ty = vim.fn.executable("ty") == 1

				if not has_project_ty and not has_global_ty and not warned_missing_ty[root] then
					vim.notify(
						"ty is not installed. Run: uv add --dev ty (or :MasonToolsInstall)",
						vim.log.levels.WARN,
						{ title = "Python LSP" }
					)
					warned_missing_ty[root] = true
				end

				vim.lsp.enable({ "ty", "ruff" })
				return true
			end,
		})
	end

	-- Simple Toggles (Fast enough to keep here if desired)
	if g.enableGo then
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "go", "gomod", "gowork", "gotmpl" },
			callback = function()
				local root = vim.fs.root(0, { "go.work", "go.mod", ".git" }) or vim.fn.getcwd()
				local missing = {}

				if vim.fn.executable("gopls") ~= 1 then
					table.insert(missing, "gopls")
				end
				if vim.fn.executable("dlv") ~= 1 then
					table.insert(missing, "dlv")
				end
				local has_go_parser = pcall(vim.treesitter.language.add, "go")
				if not has_go_parser then
					table.insert(missing, "Go Tree-sitter parser")
				end

				if #missing > 0 and not warned_missing_go[root] then
					vim.notify(
						"Missing Go tools: "
							.. table.concat(missing, ", ")
							.. "\nRun :MasonToolsInstall and :TSInstall go",
						vim.log.levels.WARN,
						{ title = "Go development" }
					)
					warned_missing_go[root] = true
				end

				vim.lsp.enable("gopls")
				return true
			end,
		})
	end
	if g.enableSql then
		vim.lsp.enable("sqls")
	end
	if g.isWindowsOs then
		vim.lsp.enable("pwsh")
	end
end

return M
