return {
	{
		"echasnovski/mini.nvim",
		version = false,
		config = function()
			require("mini.ai").setup()
			require("mini.files").setup({
			  mappings = {
			    go_in_plus = '<cr>',
			  }
			})
			require("mini.comment").setup()
			require("mini.bracketed").setup()
			require("mini.surround").setup()
			require("mini.pairs").setup()
			require("mini.indentscope").setup()
			require("mini.move").setup()
			require("mini.splitjoin").setup()
		end,
	},
}
