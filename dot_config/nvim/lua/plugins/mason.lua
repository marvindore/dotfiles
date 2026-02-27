vim.pack.add({
	-- 1. MASON CORE
	{
		src = "https://github.com/mason-org/mason.nvim",
		data = {
			cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
			on_require = { "mason", "mason-registry", "mason-core" },

			after = function(_)
				require("mason").setup({
					PATH = "append",
					ui = {
						check_outdated_packages_on_open = true,
						border = "none",
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
				})
			end,
		},
	},

	-- 2. MASON TOOL INSTALLER
	{
		src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
		data = {
			-- Wake up ONLY when you specifically ask to install or update tools
			cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsUpdateSync", "MasonToolsClean" },

			after = function(_)
				-- Autocommand for completion
				vim.api.nvim_create_autocmd("User", {
					pattern = "MasonToolsUpdateCompleted",
					callback = function()
						vim.schedule(function()
							vim.notify("mason-tool-installer has finished", vim.log.levels.INFO)
						end)
					end,
				})

				-- Base Tools
				local ensure_installed = {
					"bash-language-server",
					"dockerfile-language-server",
					"json-lsp",
					"yaml-language-server",
					"lemminx",
					"lua-language-server",
					"stylua",
					"cspell",
					"vale",
				}

				-- Conditional Language Tools
				if vim.g.enableSql then
					vim.list_extend(ensure_installed, { "sqls" })
				end
				if vim.g.enableCsharp then
					vim.list_extend(ensure_installed, { "csharpier", "netcoredbg" })
				end
				if vim.g.enableGo then
					vim.list_extend(ensure_installed, { "gopls", "delve" })
				end
				if vim.g.enableJava then
					vim.list_extend(ensure_installed, { "java-debug-adapter", "java-test", "jdtls" })
				end
				if vim.g.enableKotlin then
					vim.list_extend(ensure_installed, { "ktlint", "kotlin-debug-adapter", "kotlin-lsp" })
				end
				if vim.g.enableJavascript then
					vim.list_extend(ensure_installed, {
						"angular-language-server",
						"astro-language-server",
						"biome",
						"eslint-lsp",
						"prettier",
						"js-debug-adapter",
						"vtsls",
					})
				end
				if vim.g.enablePython then
					vim.list_extend(ensure_installed, { "debugpy", "pyrefly", "ruff" })
				end
				if vim.g.enableRust then
					vim.list_extend(ensure_installed, { "rust-analyzer", "codelldb" })
				end

				-- Setup the Installer safely (no more loop!)
				require("mason-tool-installer").setup({
					ensure_installed = ensure_installed,
					auto_update = false,
					run_on_start = false,
				})
			end,
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = spec.name or p.spec.name
		require("lze").load(spec)
	end,
})
