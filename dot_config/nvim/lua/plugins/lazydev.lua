-- 1. Install the plugins via Neovim's native package manager
vim.pack.add({
	"https://github.com/Bilal2453/luvit-meta",
	"https://github.com/folke/lazydev.nvim",
})

-- 2. Configure lazydev
-- Note: Make sure this runs BEFORE you call vim.lsp.enable("lua_ls")
vim.api.nvim_create_autocmd("FileType", {
	pattern = "lua",
	callback = function()
		require("lazydev").setup({
			library = {
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		})
	end,
})
