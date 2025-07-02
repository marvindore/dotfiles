return {
	{
		"rust-lang/rust.vim",
		enabled = vim.g.enableRust,
		ft = "rust",
		init = function()
			vim.g.rustfmt_autosave = 1
		end,
	},
	{
		"saecki/crates.nvim",
		enabled = vim.g.enableRust,
		ft = { "toml" },
		config = function()
			require("crates").setup({
				lsp = {
					enabled = true,
					on_attach = function(client, bufnr) end,
					actions = true,
					completion = true,
					hover = true,
				},
			})
		end,
	},
}
