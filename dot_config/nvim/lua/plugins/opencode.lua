vim.pack.add({
	"https://github.com/nvim-lua/plenary.nvim",
	{
		src = "https://github.com/sudo-tee/opencode.nvim",
		data = {
			cmd = { "Opencode" },
			keys = {
				{ lhs = "<leader>oo", mode = { "n" }, desc = "Toggle opencode" },
				{ lhs = "<leader>oi", mode = { "n" }, desc = "Open opencode input" },
				{ lhs = "<leader>og", mode = { "n" }, desc = "Open opencode output" },
				{ lhs = "<leader>oc", mode = { "n", "x" }, desc = "Quick chat (opencode)" },
			},
			after = function(_)
				-- Required for automatic file reloading when the agent edits code
				vim.o.autoread = true

				require("opencode").setup({
					keymap = {
						editor = {
							["<leader>oo"] = { "toggle", desc = "Toggle Opencode window" },
							["<leader>og"] = { "open_output", desc = "Open output window" },
						},
					},
				})
			end,
		},
	},
}, {
	-- Standard lze loading hook
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
