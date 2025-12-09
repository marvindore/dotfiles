return {
	{ "neovim/nvim-lspconfig" },
	{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
	-- Automatically install LSPs to stdpath for neovim
	-- Mason path ~/.local/share/nvim/mason/bin
	{
		"williamboman/mason.nvim",
		opts = {
			ui = {
				---@since 1.0.0
				-- Whether to automatically check for new versions when opening the :Mason window.
				check_outdated_packages_on_open = true,

				---@since 1.0.0
				-- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
				-- Defaults to `:h 'winborder'` if nil.
				border = nil,

				---@since 1.11.0
				-- The backdrop opacity. 0 is fully opaque, 100 is fully transparent.
				backdrop = 60,

				---@since 1.0.0
				-- Width of the window. Accepts:
				-- - Integer greater than 1 for fixed width.
				-- - Float in the range of 0-1 for a percentage of screen width.
				width = 0.8,

				---@since 1.0.0
				-- Height of the window. Accepts:
				-- - Integer greater than 1 for fixed height.
				-- - Float in the range of 0-1 for a percentage of screen height.
				height = 0.9,

				icons = {
					---@since 1.0.0
					-- The list icon to use for installed packages.
					package_installed = "◍",
					---@since 1.0.0
					-- The list icon to use for packages that are installing, or queued for installation.
					package_pending = "◍",
					---@since 1.0.0
					-- The list icon to use for packages that are not installed.
					package_uninstalled = "◍",
				},
			},
			registries = {
				"github:nvim-java/mason-registry",
				"github:mason-org/mason-registry",
				"github:Crashdummyy/mason-registry",
			},
		},
		-- dont due this because nvim-java require("mason").setup(conf) https://github.com/nvim-java/nvim-java/wiki/Troubleshooting#no_entry-mason-failed-to-install-jdtls---cannot-find-package-xxxxx
		config = function()
			require("mason").setup({
		    PATH = "append",
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup()
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
				}
				for _, value in ipairs(java_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableKotlin then
			  local kotlin_addons = {
					"ktlint",
					"kotlin-debug-adapter",
					"kotlin-lsp"
			  }
			  for _,value in ipairs(kotlin_addons) do
			    table.insert(ensure_installed, value)
        end
      end

			if vim.g.enableJavascript then
				local javascript_addons = {
					"angularls",
					"astro",
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
					"debugpy",
					"flake8",
					"ruff",
				}
				for _, value in ipairs(python_addons) do
					table.insert(ensure_installed, value)
				end
			end

			if vim.g.enableRust then
        local rust_addons = {
          "rust_analyzer",
          "codelldb"
        }

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
