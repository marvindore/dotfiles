vim.pack.add({
	{
		src = "https://github.com/zbirenbaum/copilot.lua",
		data = {
			cmd = { "Copilot" },
			event = { "InsertEnter" },
			on_require = { "copilot" },
			after = function(_)
				require("copilot").setup({
					suggestion = {
						enabled = true,
						auto_trigger = false,
					},
					panel = { enabled = false },
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
