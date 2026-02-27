vim.pack.add({
	"https://github.com/Bilal2453/luvit-meta",
	"https://github.com/folke/lazydev.nvim",
})

require("lazydev").setup({
	library = {
		{ path = "luvit-meta/library", words = { "vim%.uv" } },
	},
})
