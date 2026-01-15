return {
	{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
	{
		"mason-org/mason.nvim",
		lazy = true,
		opts = {
			-- Moved PATH here to consolidate config
			PATH = "append",
			ui = {
				check_outdated_packages_on_open = true,
				border = nil,
				backdrop = 60,
				width = 0.8,
				height = 0.9,
				icons = {
					package_installed = "◍",
					package_pending = "◍",
					package_uninstalled = "◍",
				},
			},
			registries = {
				"github:mason-org/mason-registry",
				"github:Crashdummyy/mason-registry",
			},
		},
		-- Lazy passes the 'opts' table as the second argument here
		config = function(_, opts)
			require("mason").setup(opts)

			vim.api.nvim_create_autocmd("User", {
				pattern = "MasonToolsUpdateCompleted",
				callback = function()
					vim.schedule(function()
						print("mason-tool-installer has finished")
					end)
				end,
			})

			local ensure_installed = {
				-- LSP servers
				"bash-language-server",
				"dockerfile-language-server",
				"json-lsp",
				"yaml-language-server",
				"lemminx",
				"lua-language-server",

				-- formatters / linters
				"stylua",
				"cspell",
				"vale",
			}

			if vim.g.enableSql then
				local sql_addons = { "sqls" }
				for _, value in ipairs(sql_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableCsharp then
				local cSharp_addons = { "csharpier", "netcoredbg" }
				for _, value in ipairs(cSharp_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableGo then
				local go_addons = { "gopls", "delve" }
				for _, value in ipairs(go_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableJava then
				local java_addons = { "java-debug-adapter", "java-test", "jdtls" }
				for _, value in ipairs(java_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableKotlin then
				local kotlin_addons = { "ktlint", "kotlin-debug-adapter", "kotlin-lsp" }
				for _, value in ipairs(kotlin_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableJavascript then
				local javascript_addons = {
					"angular-language-server",
					"astro-language-server",
					"biome",
					"eslint-lsp",
					"prettier",
					"js-debug-adapter",
					"vtsls",
				}
				for _, value in ipairs(javascript_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enablePython then
				local python_addons = {
					"basedpyright",
					"black",
					"debugpy",
					"flake8",
					"ruff",
				}
				for _, value in ipairs(python_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableRust then
				local rust_addons = { "rust-analyzer", "codelldb" }
				for _, value in ipairs(rust_addons) do
					table.insert(ensure_installed, value)
				end
			end

			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed,
				auto_update = false,
				run_on_start = false,
			})
		end,
	},
}
