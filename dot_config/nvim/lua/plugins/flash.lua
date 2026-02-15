vim.pack.add({
	{
		src = "https://github.com/folke/flash.nvim",
		data = {
			-- Lazy load only when these specific keys are pressed
			keys = {
				{
					lhs = "s",
					rhs = function()
						require("flash").jump()
					end,
					mode = { "n", "x", "o" },
					desc = "Flash",
				},
				{
					lhs = "S",
					rhs = function()
						require("flash").jump({ search = { forward = false, wrap = false, multi_window = false } })
					end,
					mode = { "n", "x", "o" },
					desc = "Flash Backward",
				},
				{
					lhs = "r",
					rhs = function()
						require("flash").remote()
					end,
					mode = { "o" },
					desc = "Remote Flash",
				},
				{
					lhs = "R",
					rhs = function()
						require("flash").treesitter_search()
					end,
					mode = { "o", "x" },
					desc = "Treesitter Search",
				},
				{
					lhs = "<c-s>",
					rhs = function()
						require("flash").toggle()
					end,
					mode = { "c" },
					desc = "Toggle Flash Search",
				},
			},

			after = function(_)
				require("flash").setup({
					modes = {
						char = { enabled = false },
					},
				})
			end,
		},
	},
}, {
	-- Hand the data over to lze for lazy-loading, it won't trigger until the
	-- exact millisecond you trigger a keymap press
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
