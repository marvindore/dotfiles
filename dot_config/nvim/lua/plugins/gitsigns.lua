-- Hunk navigation: defer to Vim's built-in diff-mode ]c/[c inside 'diff'
-- windows (diffview.nvim, :diffthis, etc.); use gitsigns everywhere else.
local function nav_hunk_or_diff(direction, builtin_key)
	return function()
		if vim.wo.diff then
			vim.cmd("normal! " .. builtin_key)
		else
			require("gitsigns").nav_hunk(direction)
		end
	end
end

----------------------------------------------------------------------
-- PR review mode: diff every buffer against the merge-base with a target
-- branch, so signs, ]c/[c, previews and word diff show the whole PR.
----------------------------------------------------------------------
local review_ref -- nil when review mode is off

local function git(args, cwd)
	local res = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
	if res.code ~= 0 then
		return nil
	end
	return vim.trim(res.stdout)
end

local function current_dir()
	local name = vim.api.nvim_buf_get_name(0)
	if name ~= "" and vim.uv.fs_stat(name) then
		return vim.fs.dirname(name)
	end
	return vim.uv.cwd()
end

local function pr_review_start(ref)
	local dir = current_dir()
	if not ref or ref == "" then
		ref = git({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, dir) or "origin/main"
	end
	local sha = git({ "merge-base", ref, "HEAD" }, dir)
	if not sha then
		vim.notify("PR review: no merge-base with " .. ref, vim.log.levels.WARN)
		return
	end
	review_ref = ref
	local gs = require("gitsigns")
	gs.change_base(sha, true)
	gs.toggle_word_diff(true)
	vim.notify("PR review: diff against merge-base with " .. ref, vim.log.levels.INFO)
end

local function pr_review_stop()
	review_ref = nil
	local gs = require("gitsigns")
	gs.change_base(nil, true)
	gs.toggle_word_diff(false)
	vim.notify("PR review: off", vim.log.levels.INFO)
end

local function pr_review_toggle()
	if review_ref then
		pr_review_stop()
	else
		pr_review_start()
	end
end

vim.api.nvim_create_user_command("PRReview", function(opts)
	pr_review_start(opts.args)
end, { nargs = "?", desc = "Diff buffers against merge-base with <ref> (default origin HEAD)" })
vim.api.nvim_create_user_command("PRReviewStop", pr_review_stop, {})

local sign = { text = "▏" }

vim.pack.add({
	{
		src = "https://github.com/lewis6991/gitsigns.nvim",
		data = {
			keys = {
				{ lhs = "<leader>gs",  rhs = ":lua require('gitsigns').show_commit()<cr>", mode = "n", desc =  "Git show commit" },
				{ lhs = "[c", rhs = nav_hunk_or_diff("prev", "[c"), mode = { "n", "x" }, desc = "Previous hunk / diff change" },
				{ lhs = "]c", rhs = nav_hunk_or_diff("next", "]c"), mode = { "n", "x" }, desc = "Next hunk / diff change" },
				{ lhs = "[C", rhs = nav_hunk_or_diff("first", "[c"), mode = { "n", "x" }, desc = "First hunk / diff change" },
				{ lhs = "]C", rhs = nav_hunk_or_diff("last", "]c"), mode = { "n", "x" }, desc = "Last hunk / diff change" },
				{ lhs = "ih", rhs = ":<C-U>Gitsigns select_hunk<cr>", mode = { "o", "x" }, desc = "Inner hunk" },
				-- <leader>gb / <leader>gB belong to Snacks (blame in browser), see snacks.lua
				{ lhs = "<leader>gl",  rhs = ":lua require('gitsigns').blame_line()<cr>", mode = "n", desc =  "Git blame line (popup)" },
				{ lhs = "<leader>gd",  rhs = ":lua require('gitsigns').preview_hunk_inline()<cr>", mode = "n", desc =  "Preview hunk inline" },
				{ lhs = "<leader>ghs", rhs = ":lua require('gitsigns').stage_hunk()<cr>", mode = "n", desc =  "Git Stage Hunk" },
				{ lhs = "<leader>ghr", rhs = ":lua require('gitsigns').reset_hunk()<cr>", mode = "n", desc =  "Git Reset Hunk" },
				{ lhs = "<leader>gR", rhs = pr_review_toggle, mode = "n", desc = "PR review mode: toggle" },
				{ lhs = "<leader>gq", rhs = ":lua require('gitsigns').setqflist('all')<cr>", mode = "n", desc = "Git hunks (all files) to quickfix" },
				{ lhs = "<leader>ga", rhs = ":Gitsigns blame<cr>", mode = "n", desc =  "Git Blame annotate (blame file split)" },
			},
			-- Lazy load only when a buffer is opened or created
			event = { "BufReadPre", "BufNewFile" },
			on_require = { "gitsigns" },

			after = function(_)
				-- diff_opts default to 'diffopt' (histogram, linematch:60, indent-heuristic in settings.lua)
				require("gitsigns").setup({
					signs = { add = sign, change = sign, delete = sign, topdelete = sign, changedelete = sign, untracked = sign },
					signs_staged = { add = sign, change = sign, delete = sign, topdelete = sign, changedelete = sign },
					sign_priority = 199,
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
