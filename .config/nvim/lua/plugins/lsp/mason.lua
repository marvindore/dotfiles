return {
	{ "neovim/nvim-lspconfig" },
	{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
	-- Automatically install LSPs to stdpath for neovim
	-- Mason path ~/.local/share/nvim/mason/bin
	{
		"williamboman/mason.nvim",
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
			registries = {
				"github:nvim-java/mason-registry",
				"github:mason-org/mason-registry",
			},
		},
		-- dont due this because nvim-java require("mason").setup(conf) https://github.com/nvim-java/nvim-java/wiki/Troubleshooting#no_entry-mason-failed-to-install-jdtls---cannot-find-package-xxxxx
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "MasonToolsUpdateCompleted",
				callback = function()
					vim.schedule(function()
						print("mason-tool-installer has finished")
					end)
				end,
			})

			local ensure_installed = {
				"bashls",
				"cspell",
				"dockerls",
				"jsonls",
				"lemminx",
				"lua_ls",
				"tailwindcss",
				"yamlls",
				"sqlls",
				"stylua",
				"vale",
			}

			if vim.g.enableCsharp then
				local cSharp_addons = {
					"csharpier",
					"netcoredbg",
					"roslyn",
				}
				for _, value in ipairs(cSharp_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableGo then
				local go_addons = {
					"gopls",
					"delve",
				}
				for _, value in ipairs(go_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableJava then
				local java_addons = {
					"java-debug-adapter",
					"java-test",
					"jdtls",
					"ktlint",
					"kotlin-debug-adapter",
				}
				for _, value in ipairs(java_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableJavascript then
				local javascript_addons = {
					"angularls",
					"biome",
					"eslint",
					"prettier",
					"js-debug-adapter",
				}
				for _, value in ipairs(javascript_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enablePython then
				local python_addons = {
					"basedpyright",
					"black",
					"flake8",
					"ruff",
				}
				for _, value in ipairs(python_addons) do
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
