vim.pack.add({
	-- Optional dependency for icon support
	"https://github.com/nvim-tree/nvim-web-devicons",

	{
		src = "https://github.com/ibhagwan/fzf-lua",
		data = {
			-- 1. Load if you manually run the command
			cmd = { "FzfLua" },

			keys = {
        { lhs = "<leader>fn", rhs = "<cmd>lua require('fzf-lua').files({ cwd = vim.fn.expand('~/.local/share/chezmoi/cheatsheets') })<CR>", mode = "n", desc = "Cheatsheet find"},
        { lhs = "<leader>fN", rhs = "<cmd>lua require('fzf-lua').live_grep({ cwd = vim.fn.expand('~/.local/share/chezmoi/cheatsheets') })<CR>", mode = "n", desc = "Cheatsheets grep"},
				{ lhs = "<leader>fo", rhs = ":lua require('fzf-lua').oldfiles()<CR>", mode = "n", desc =  "Fzf open old files" },
				{ lhs = "<LocalLeader>ff", rhs = ":lua require('fzf-lua').files()<CR>", mode = "n", desc =  "Fzf Files" },
				{ lhs = "<LocalLeader>fr", rhs = ":lua require('fzf-lua').resume()<CR>", mode = "n", desc =  "Fzf Resume" },
				{ lhs = "<LocalLeader>fg", rhs = ":lua require('fzf-lua').grep_project()<CR>", mode = "n", desc =  "Fzf Grep" },
				{ lhs = "<LocalLeader>fG", rhs = ":lua require('fzf-lua').live_grep_glob()<CR>", mode = "n", desc =  "Fzf rg --glob" },
				{
					lhs = "<LocalLeader>fd",
					rhs = ":lua require('fzf-lua').diagnostics_document()<CR>",
					mode = "n",
					desc = "Fzf Document Diagnostics",
				},
				{
					lhs = "<LocalLeader>fD",
					rhs = ":lua require('fzf-lua').diagnostics_workspace()<CR>",
					mode = "n",
					desc = "Fzf Workspace Diagnostics",
				},
				{
					lhs = "<LocalLeader>fl",
					rhs = ":lua require('fzf-lua').live_grep()<CR>",
					mode = "n",
					desc = "Fzf Live Grep Current Project",
				},
				{
					lhs = "<LocalLeader>fc",
					rhs = ":lua require('fzf-lua').lgrep_curbuf()<CR>",
					mode = "n",
					desc = "Fzf Live Grep Current Buffer",
				},
				{
					lhs = "<LocalLeader>fu",
					rhs = ":lua require('fzf-lua').grep_cword()<CR>",
					mode = "n",
					desc = "Fzf Grep Word Under Cursor",
				},
				{
					lhs = "ml",
					rhs = 'function() require("fzf-lua").marks({marks = "[A-Za-z]"}) end',
					mode = "n",
					desc = "Filtered Marks (a-z, A-Z)",
				},
			},

			-- 2. CRITICAL: Load when LSP attaches so your lsp_setup.lua pickers work!
			event = "LspAttach",

			after = function(_)
				require("fzf-lua").setup({})
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
