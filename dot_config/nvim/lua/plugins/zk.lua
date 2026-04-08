vim.pack.add({
	{
		src = "https://github.com/zk-org/zk-nvim.git",
		data = {
			-- ✅ These commands will now auto-load zk.nvim
			cmds = { "ZkNew", "ZkNotes", "ZkTags", "ZkLinks", "ZkBacklinks", "ZkRename", "ZkMatch" },
			keys = {
				-- new note
				{
					mode = "n",
					lhs = "<leader>nn",
					rhs = "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>",
					desc = "Notes new",
				},
				-- open note
				{
					mode = "n",
					lhs = "<leader>no",
					rhs = "<Cmd>ZkNotes { sort = { 'modified' } }<CR>",
					desc = "Notes open",
				},
				-- find note
				{
					mode = "n",
					lhs = "<leader>nf",
					rhs = "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
					desc = "Notes find",
				},
				-- open tags
				{ mode = "n", lhs = "<leader>nt", rhs = "<Cmd>ZkTags<CR>", desc = "Notes open tag" },
				-- notes match selection
				{ mode = "v", lhs = "<leader>nf", rhs = ":'<,'>ZkMatch<CR>", desc = "Notes find selected" },
			},
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

-- ============================================================
-- ZK / Markdown UX Enhancements (mkdnflow-like ergonomics)
-- Lazy-safe with vim.pack + lze (triggering loads via :* commands)
-- ============================================================

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(event)
		local buf = event.buf

		-- --------------------------------------------------------
		-- <CR> → follow markdown link
		-- - external URL → browser
		-- - local file → open
		-- --------------------------------------------------------

		vim.keymap.set("n", "<CR>", function()
			local line = vim.api.nvim_get_current_line()
			local col = vim.api.nvim_win_get_cursor(0)[2] + 1

			local before = line:sub(1, col)
			local after = line:sub(col)
			local link = before:match("%(([^)]+)$") or after:match("^([^)]*)%)")

			if not link then
				vim.cmd("normal! <CR>")
				return
			end

			if link:match("^https?://") then
				vim.ui.open(link)
			else
				vim.cmd("normal! gf")
			end
		end, { buffer = buf })

		-- --------------------------------------------------------
		-- <CR><CR> → create Zettel from word under cursor
		-- (true mkdnflow gesture, lazy-safe)
		-- --------------------------------------------------------

		vim.keymap.set("n", "<CR><CR>", function()
			local word = vim.fn.expand("<cword>")
			if word == "" then
				return
			end

			local title = word:gsub("_", " "):gsub("-", " "):gsub("(%l)(%u)", "%1 %2"):gsub("^%l", string.upper)

			require("lze").trigger_load("zk-nvim")
			require("zk").new({ title = title })
		end, {
			buffer = true,
			desc = "ZK: create Zettel from word",
		})

		-- --------------------------------------------------------
		-- Visual → create Zettel from selection
		-- --------------------------------------------------------

		vim.keymap.set(
			"v",
			"<leader>zn",
			"<Cmd>ZkNew { title = getline(\"'<\", \"'>\"), filename = '{{id}}-{{slug}}.md', template = 'default' }<CR>",
			{
				buffer = buf,
				desc = "ZK: create Zettel from selection",
			}
		)

		-- --------------------------------------------------------
		-- Open existing note matching word under cursor
		-- --------------------------------------------------------

		vim.keymap.set(
			"n",
			"<leader>zo",
			"<Cmd>lua vim.cmd('ZkNotes { match = { ' .. string.format('%q', vim.fn.expand('<cword>')) .. ' } }')<CR>",
			{
				buffer = buf,
				desc = "ZK: open matching note",
			}
		)

		-- --------------------------------------------------------
		-- Insert link to existing note (fzf-lua)
		-- --------------------------------------------------------
		vim.keymap.set("n", "<leader>zl", "<Cmd>ZkLinks<CR>", {
			buffer = buf,
			desc = "ZK: insert link",
		})

		-- --------------------------------------------------------
		-- Show backlinks
		-- --------------------------------------------------------
		vim.keymap.set("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", {
			buffer = buf,
			desc = "ZK: show backlinks",
		})

		-- --------------------------------------------------------
		-- Rename note safely (keeps ID stable)
		-- --------------------------------------------------------
		vim.keymap.set("n", "<leader>zr", "<Cmd>ZkRename<CR>", {
			buffer = buf,
			desc = "ZK: rename note",
		})

		-- --------------------------------------------------------
		-- Create related note from current context
		-- --------------------------------------------------------

		vim.keymap.set("n", "<leader>ze", function()
			vim.ui.input({ prompt = "Related note: " }, function(input)
				if not input or input == "" then
					return
				end
				vim.cmd(
					"ZkNew { title = "
						.. vim.fn.string(input)
						.. ", filename = '{{id}}-{{slug}}.md', template = 'default' }"
				)
			end)
		end, { buffer = buf })

		-- --------------------------------------------------------
		-- Insert today's date
		-- --------------------------------------------------------
		vim.keymap.set("n", "<leader>zd", function()
			vim.api.nvim_put({ os.date("%Y-%m-%d") }, "c", true, true)
		end, {
			buffer = buf,
			desc = "Insert date",
		})

		-- --------------------------------------------------------
		-- Toggle markdown TODO checkbox
		-- --------------------------------------------------------
		vim.keymap.set("n", "<leader>zt", function()
			vim.cmd("normal! 0f[lt]r[x]")
		end, {
			buffer = buf,
			desc = "Toggle TODO",
		})
	end,
})
