vim.pack.add({
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-context",
		data = {
			-- It is perfectly safe to lazy-load this specific UI plugin
			-- because the core parser is already running in the background.
			event = { "BufReadPost", "BufNewFile" },

			after = function(_)
				require("treesitter-context").setup({
					enable = false, -- Plugin starts disabled as per your config
					multiwindow = false, -- Enable multiwindow support
					max_lines = 0, -- No limit on context height
					min_window_height = 0, -- No limit on editor height
					line_numbers = true,
					multiline_threshold = 20, -- Max lines for a single scope
					trim_scope = "outer", -- Discard outer lines if max_lines exceeded
					mode = "cursor", -- Calculate context based on cursor position
					separator = nil, -- No separator line
					zindex = 20, -- Window layer priority
					on_attach = nil, -- Default attach logic
				})
			end,
		},
	},
}, {
	-- Standard lze loading hook
	load = function(p)
		local spec = p.spec.data or {}
		-- Ensure the name is captured correctly for the hook
		spec.name = spec.name or p.spec.name
		require("lze").load(spec)
	end,
})


--map("n", "<localLeader>at", "<cmd>TSContext toggle<cr>", "Toggle TSContext")
