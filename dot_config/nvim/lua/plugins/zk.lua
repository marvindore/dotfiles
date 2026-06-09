vim.pack.add({
	{
		src = "https://github.com/zk-org/zk-nvim.git",
		data = {
			-- ✅ These commands will now auto-load zk.nvim
			cmds = { "ZkNew", "ZkNotes", "ZkTags", "ZkLinks", "ZkBacklinks", "ZkRename", "ZkMatch" },
			keys = {
				-- find or create note (unified picker)
				{
					mode = "n",
					lhs = "<leader>nn",
					rhs = "<Cmd>ZkFindOrCreate<CR>",
					desc = "Notes find or create",
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
-- FindOrCreateNote: unified find-or-create picker (Logseq-style)
-- Uses Snacks.picker (always loaded, no lazy-load issues).
-- Enter on a match → open note.
-- Enter with no match, or Ctrl-N → create note from typed query.
-- ============================================================

local function FindOrCreateNote()
	-- When launched via `nvim -c 'ZkFindOrCreate'`, -c fires before VimEnter.
	-- Auto-session restores the session on VimEnter and would close the picker.
	-- Register a VimEnter hook (which runs after auto-session's own VimEnter
	-- callback, since ours is registered later) so the picker opens on top of
	-- any restored session state.
	if vim.v.vim_did_enter == 0 then
		vim.api.nvim_create_autocmd("VimEnter", {
			once = true,
			callback = function() vim.schedule(FindOrCreateNote) end,
		})
		return
	end

	local notes_dir = vim.fn.expand("~/notes")
	vim.cmd("cd " .. vim.fn.fnameescape(notes_dir))

	local output = vim.fn.system(
		"zk list --format '{{title}}\t{{absPath}}' --sort modified --notebook-dir "
			.. vim.fn.shellescape(notes_dir)
	)

	local items = {}
	for line in (output or ""):gmatch("[^\n]+") do
		local parts = vim.split(line, "\t", { plain = true })
		local title = parts[1] or ""
		local path = parts[2] or ""
		if path ~= "" then
			table.insert(items, {
				text = title ~= "" and title or vim.fn.fnamemodify(path, ":t:r"),
				file = path,
			})
		end
	end

	Snacks.picker.pick("notes", {
		items = items,
		format = "text",
		prompt = "Notes❯ ",
		actions = {
			create_note = function(picker)
				local query = vim.trim(picker.input.filter.pattern or "")
				picker:close()
				if query ~= "" then
					require("lze").trigger_load("zk-nvim")
					require("zk").new({ title = query })
				end
			end,
		},
		win = {
			input = {
				keys = {
					["<c-n>"] = { "create_note", mode = { "i", "n" } },
				},
			},
		},
		confirm = function(picker, item)
			local query = vim.trim(picker.input.filter.pattern or "")
			picker:close()
			if item then
				vim.cmd("edit " .. vim.fn.fnameescape(item.file))
			elseif query ~= "" then
				require("lze").trigger_load("zk-nvim")
				require("zk").new({ title = query })
			end
		end,
	})
end

vim.api.nvim_create_user_command("ZkFindOrCreate", FindOrCreateNote, {})

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

		-- Helper: return markdown link target under cursor if cursor is within the link span
		local function markdown_target_at_cursor(line, col1)
			local init = 1
			while true do
				local s, e, _text, target = line:find("%[([^%]]+)%]%(([^)]+)%)", init)
				if not s then
					break
				end
				if col1 >= s and col1 <= e then
					return target
				end
				init = e + 1
			end
		end

		vim.keymap.set("n", "<CR>", function()
			local line = vim.api.nvim_get_current_line()
			local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
			local col1 = col0 + 1 -- Lua strings are 1-based

			-- 1) Prefer markdown link parsing: [text](target)
			local target = markdown_target_at_cursor(line, col1)

			if target then
				if target:match("^https?://") then
					vim.ui.open(target)
				else
					-- Open local file path directly (predictable and explicit)
					vim.cmd("edit " .. vim.fn.fnameescape(target))
				end
				return
			end

			-- 2) Small improvement: fallback to cfile (URL or path) without normal-mode side effects
			local cfile = vim.fn.expand("<cfile>")
			if cfile and cfile ~= "" then
				if cfile:match("^https?://") then
					vim.ui.open(cfile)
					return
				end

				-- If it looks like a path, try opening it.
				-- (You can add stronger heuristics here if you want.)
				if cfile:find("[/\\]") or cfile:match("%.%w+$") then
					vim.cmd("edit " .. vim.fn.fnameescape(cfile))
					return
				end
			end

			-- 3) Otherwise preserve default Enter behavior
			vim.cmd("normal! <CR>")
		end, { buffer = buf, silent = true })

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

		-- --------------------------------------------------------
		-- Open or create today's journal note
		-- --------------------------------------------------------
		vim.keymap.set("n", "<leader>nj", function()
			local date = os.date("%Y-%m-%d")
			local journals_dir = vim.fn.expand("~/notes/journals")
			local path = journals_dir .. "/" .. date .. ".md"
			vim.fn.mkdir(journals_dir, "p")
			if vim.fn.filereadable(path) == 0 then
				local lines = {
					"---",
					"title: " .. date,
					"tags: [journal]",
					"---",
					"",
					"## Notes",
					"",
					"",
					"## Tasks",
					"",
					"",
					"## Decisions",
					"",
				}
				vim.fn.writefile(lines, path)
			end
			vim.cmd("edit " .. vim.fn.fnameescape(path))
		end, { buffer = buf, desc = "Notes: open today's journal" })
	end,
})
