-- ESLint LS. Attaches only when the buffer is under an ESLint config.
-- root_dir / before_init / handlers follow nvim-lspconfig's lsp/eslint.lua (not installed here).
local eslint_config_files = {
	".eslintrc",
	".eslintrc.js",
	".eslintrc.cjs",
	".eslintrc.yaml",
	".eslintrc.yml",
	".eslintrc.json",
	"eslint.config.js",
	"eslint.config.mjs",
	"eslint.config.cjs",
	"eslint.config.ts",
	"eslint.config.mts",
	"eslint.config.cts",
}

local LOCKFILES = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }

-- package.json with an "eslintConfig" key also counts as an ESLint config.
local function package_json_has_eslint(dir)
	local f = io.open(vim.fs.joinpath(dir, "package.json"), "r")
	if not f then
		return false
	end
	local content = f:read("*a")
	f:close()
	return content:find('"eslintConfig"', 1, true) ~= nil
end

local function uses_eslint(filename, project_root)
	local found = vim.fs.find(eslint_config_files, {
		path = filename,
		type = "file",
		limit = 1,
		upward = true,
		stop = vim.fs.dirname(project_root),
	})[1]
	return found ~= nil or package_json_has_eslint(project_root)
end

return {
	cmd = function(dispatchers, config)
		local cmd = "vscode-eslint-language-server"
		local local_cmd = vim.fs.joinpath(config.root_dir, "node_modules", ".bin", cmd)
		if vim.fn.executable(local_cmd) == 1 then
			cmd = local_cmd
		end
		return vim.lsp.rpc.start({ cmd, "--stdio" }, dispatchers)
	end,
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"vue",
		"svelte",
		"astro",
		"htmlangular",
	},
	root_dir = function(bufnr, on_dir)
		if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
			return
		end
		local project_root = vim.fs.root(bufnr, { LOCKFILES, { ".git" } }) or vim.fn.getcwd()
		if uses_eslint(vim.api.nvim_buf_get_name(bufnr), project_root) then
			on_dir(project_root)
		end
	end,
	before_init = function(_, config)
		config.settings.workspaceFolder = {
			uri = vim.uri_from_fname(config.root_dir),
			name = vim.fn.fnamemodify(config.root_dir, ":t"),
		}
	end,
	handlers = {
		["eslint/openDoc"] = function(_, result)
			if result then
				vim.ui.open(result.url)
			end
			return {}
		end,
		["eslint/confirmESLintExecution"] = function(_, result)
			if not result then
				return
			end
			return 4 -- approved
		end,
		["eslint/probeFailed"] = function()
			vim.notify("ESLint probe failed.", vim.log.levels.WARN)
			return {}
		end,
		["eslint/noLibrary"] = function()
			vim.notify("Unable to find ESLint library.", vim.log.levels.WARN)
			return {}
		end,
	},
	settings = {
		codeAction = {
			disableRuleComment = {
				enable = true,
				location = "separateLine",
			},
			showDocumentation = {
				enable = true,
			},
		},
		codeActionOnSave = {
			enable = false,
			mode = "all",
		},
		experimental = {},
		format = false, -- conform/prettier owns formatting
		nodePath = "",
		onIgnoredFiles = "off",
		problems = {
			shortenToSingleLine = false,
		},
		quiet = false,
		rulesCustomizations = {},
		run = "onType",
		useESLintClass = false,
		validate = "on",
		workingDirectory = {
			mode = "location",
		},
	},
}
