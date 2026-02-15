vim.pack.add({
	{
		src = "https://github.com/kevinhwang91/nvim-hlslens",
		data = {
			-- Lazy load exactly when you trigger a search command
			keys = {
				{
					lhs = "n",
					rhs = [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
					mode = { "n" },
					silent = true,
				},
				{
					lhs = "N",
					rhs = [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
					mode = { "n" },
					silent = true,
				},
				{
					lhs = "*",
					rhs = [[*<Cmd>lua require('hlslens').start()<CR>]],
					mode = { "n" },
					silent = true,
				},
				{
					lhs = "#",
					rhs = [[#<Cmd>lua require('hlslens').start()<CR>]],
					mode = { "n" },
					silent = true,
				},
				{
					lhs = "g*",
					rhs = [[g*<Cmd>lua require('hlslens').start()<CR>]],
					mode = { "n" },
					silent = true,
				},
				{
					lhs = "g#",
					rhs = [[g#<Cmd>lua require('hlslens').start()<CR>]],
					mode = { "n" },
					silent = true,
				},
				{
					lhs = "<Leader>l",
					rhs = [[<Cmd>noh<CR><Cmd>lua require('hlslens').stop()<CR>]],
					mode = { "n" },
					silent = true,
				},
				{
					lhs = "<Esc>",
					rhs = [[<Esc><Cmd>noh<CR><Cmd>lua require('hlslens').stop()<CR>]],
					mode = { "n" },
					silent = true,
				},
			},

			after = function(_)
				require("hlslens").setup({
					calm_down = true,
					nearest_only = true,
				})
			end,
		},
	},
}, {
	-- Hand the data over to lze for lazy-loading
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
