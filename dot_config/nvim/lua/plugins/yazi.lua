vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim",
	{
		src = "https://github.com/mikavilpas/yazi.nvim",
		data = {
			cmds = { "Yazi" },
			keys = {
				{
					mode = { "n", "v" },
					lhs = "-",
					rhs = "<Cmd>Yazi<CR>",
					desc = "Open yazi at the current file",
				},
				{
					mode = "n",
					lhs = "_",
					rhs = "<Cmd>Yazi cwd<CR>",
					desc = "Open yazi in the working directory",
				},
        {
          mode = "n",
          lhs = "<leader>-",
          rhs = "<Cmd>Yazi toggle<cr>",
          desc = "Resume the lasy yazi session",
        },
			},
			after = function()
				require("yazi").setup({
					open_for_directories = false,
					keymaps = {
						show_help = "<F1>",
					},
				})
			end,
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
