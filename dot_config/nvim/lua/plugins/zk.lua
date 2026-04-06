vim.pack.add({
	{
		src = "https://github.com/zk-org/zk-nvim.git",
		data = {
		  keys = {
		    -- new note
				{ mode = "n", lhs = "<leader>nn", rhs = "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", desc = "Notes new" },
				-- open note
        { mode = "n", lhs = "<leader>no", rhs = "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", desc = "Notes open" },
        -- find note
        { mode = "n", lhs = "<leader>nf", rhs = "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>", desc = "Notes find" },
        -- open tags
        { mode = "n", lhs = "<leader>nt", rhs = "<Cmd>ZkTags<CR>", desc = "Notes open tag" },
        -- notes match selection
        { mode = "v", lhs = "<leader>nf", rhs = ":'<,'>ZkMatch<CR>", desc = "Notes find selected" },
		  }
		}
	},
},
{
	-- Standard lze loading hook
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
