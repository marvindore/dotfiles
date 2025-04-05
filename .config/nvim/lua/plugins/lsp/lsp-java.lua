return {
	"nvim-java/nvim-java",
	event = { "BufEnter *.java" },
	enabled = vim.g.enableJava,
	dependencies = {
		"nvim-java/lua-async-await",
		"nvim-java/nvim-java-core",
		"nvim-java/nvim-java-test",
		"nvim-java/nvim-java-dap",
		"MunifTanjim/nui.nvim",
		"neovim/nvim-lspconfig",
		"mfussenegger/nvim-dap",
		"williamboman/mason.nvim",
	},
	config = function()
		require("java").setup({
			jdk = {
				auto_install = false,
			},
			root_markers = {
				"settings.gradle",
				"settings.gradle.kts",
				"pom.xml",
				"build.gradle",
				"mvnw",
				"gradlew",
				"build.gradle",
				"build.gradle.kts",
			},
			lombok = {
				version = "nightly",
			},
			jdtls = {
				version = "v1.43.0",
			},
			java_test = {
				enable = true,
				version = "0.43.0",
			},
			-- load java debugger plugins
			java_debug_adapter = {
				enable = true,
				version = "0.58.1",
			},

			spring_boot_tools = {
				enable = true,
				version = "1.59.0",
			},
		})
		local lspconfig = require("lspconfig")

		lspconfig.jdtls.setup({
			settings = {
				java = {
					configuration = {
						runtimes = {
							{
								name = "JavaSE-21",
								path = vim.g.homeDir .. "/.asdf/installs/java/zulu-21.38.21",
								default = true,
							},
						},
					},
				},
			},
		})
	end,
}
