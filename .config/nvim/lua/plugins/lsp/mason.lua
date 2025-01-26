return {
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
		},
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
}
