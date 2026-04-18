-- 1) Add the plugin natively (clones the source)
vim.pack.add({
  "https://github.com/folke/snacks.nvim",
})

-- 2) Configuration Setup
local opts = {
  bigfile  = { enabled = true },
  gh = { enabled = true },
  image = { enabled = true },
  lazygit  = { enabled = true }, -- Snacks' LazyGit module
  notifier = { enabled = true },
  notify   = { enabled = true },
  picker   = {
    enabled = true,
    opts = { formatters = { truncate = false } },
    --layout = { preset = "ivy" },
    win = {
      input   = { keys = { ["<c-]>"] = { "focus_preview", mode = { "n", "i" } } } },
      list    = { keys = { ["<c-]>"] = { "focus_preview", mode = { "n" } } } },
      preview = { keys = {
        ["?"] = "toggle_help_list",
      } },
    },
  },
  quickfile = { enabled = true },
  zen = {
    enabled = true,
    width = 0,
    toggles = {
      dim = true,
      git_signs = false,
      diagnostics = false,
      linenumber = true,
      relativenumber = false,
      indent = false,
    },
    zoom = {
      show = { statusline = false, tabline = false },
      win = { backdrop = false, width = 0 },
      toggles = {
        dim = true,
        git_signs = false,
        diagnostics = false,
        linenumber = true,
        relativenumber = false,
        indent = false,
      },
    },
  },
}

-- 3) Run the setup
require("snacks").setup(opts)

-- 3.5) Preview pane navigation
-- win.preview.keys only fires on the initial scratch buffer; when the preview
-- switches to a real file buffer via set_buf(), that buffer never gets map() called.
-- This autocmd re-registers <c-p> on every buffer the preview window displays.
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local is_scratch = vim.bo[buf].filetype == "snacks_picker_preview"
    local ok, previewed = pcall(vim.api.nvim_buf_get_var, buf, "snacks_previewed")
    if not (is_scratch or (ok and previewed)) then return end
    vim.keymap.set("n", "<c-p>", function()
      local pickers = Snacks.picker.get()
      if not (pickers and pickers[1]) then return end
      local lw = pickers[1].list.win.win
      if lw and vim.api.nvim_win_is_valid(lw) then
        vim.api.nvim_set_current_win(lw)
      end
    end, { buffer = buf, nowait = true, silent = true })
  end,
})

-- 4) Keymaps (Standard Vim keymap API for eager loading)
local set = vim.keymap.set

-- Zen & Utilities
set("n", "<leader>bz", function() Snacks.zen.zoom() end, { desc = "Toggle Zen Mode" })
set("n", "<leader>fe", function() Snacks.explorer() end, { desc = "File Explorer" })

-- Finders
set("n", "<leader>fs", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })
set("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find Files" })
set("n", "<leader>fF", function() Snacks.picker.files({ hidden = true }) end, { desc = "Find Hidden Files" })
set("n", "<leader>f.", function() Snacks.picker.files({ cwd = vim.fn.expand("%:p:h") }) end, { desc = "Find File In Current Dir" })
set("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Grep Files" })
set("n", "<leader>fG", function() Snacks.picker.grep({ hidden = true }) end, { desc = "Grep Hidden Files" })
set("n", "<leader>f.", function() Snacks.picker.resume() end, { desc = "Resume Find" })
set("n", "<leader>fj", function() Snacks.picker.jumps() end, { desc = "Jumps" })
set("n", "<leader>fq", function() Snacks.picker.qflist() end, { desc = "Quickfix List" })
set("n", "<S-h>", function() Snacks.picker.buffers() end, { desc = "Buffers" })
set("n", "<leader>fm", function() Snacks.picker.marks() end, { desc = "Marks" })

-- Github
set("n", "<leader>gii", function() Snacks.picker.gh_issue() end,                          { desc = "Issues (open)" })
set("n", "<leader>giI", function() Snacks.picker.gh_issue({ state = "all" }) end,         { desc = "Issues (all)" })
set("n", "<leader>gio", function() Snacks.picker.gh_pr({ confirm = "gh_open" }) end,      { desc = "PR Open in Snacks gh" })
set("n", "<leader>gip", function() Snacks.picker.gh_pr() end,                             { desc = "PRs (open)" })
set("n", "<leader>giP", function() Snacks.picker.gh_pr({ state = "all" }) end,            { desc = "PRs (all)" })
set("n", "<leader>giw", function()
  Snacks.picker.gh_pr({
    confirm = function(picker, item)
      if item then
        picker:close()
        vim.fn.jobstart({ "gh", "pr", "view", tostring(item.number), "--web" }, {
          detach = true,
          env = { BROWSER = "open" },
        })
      end
    end,
  })
end, { desc = "PR Open in Browser (pick)" })

set("n", "<leader>gid", function()
	Snacks.picker.gh_pr({
		confirm = function(picker, item)
			if not item then return end
			picker:close()

			local pr_number    = tostring(item.number)
			local worktree_dir = vim.fn.stdpath("data") .. "/pr-worktrees"
			local worktree_path = worktree_dir .. "/pr-" .. pr_number

			local function launch_diffview(head_ref, base_ref)
				vim.fn.mkdir(worktree_dir, "p")

				if vim.fn.isdirectory(worktree_path) == 1 then
					vim.notify("[PR] Reusing worktree for #" .. pr_number, vim.log.levels.INFO)
					require("diffview").open({ "-C" .. worktree_path, "origin/" .. base_ref .. "...HEAD", "--imply-local" })
					return
				end

				vim.notify("[PR] Fetching " .. head_ref .. "...", vim.log.levels.INFO)
				vim.system({ "git", "fetch", "origin", head_ref }, {}, function(r1)
					if r1.code ~= 0 then
						vim.schedule(function()
							vim.notify("[PR] fetch failed:\n" .. (r1.stderr or ""), vim.log.levels.ERROR)
						end)
						return
					end

					vim.system({ "git", "worktree", "add", "--detach", worktree_path, "origin/" .. head_ref }, {}, function(r2)
						if r2.code ~= 0 then
							vim.schedule(function()
								vim.notify("[PR] worktree add failed:\n" .. (r2.stderr or ""), vim.log.levels.ERROR)
							end)
							return
						end

						vim.schedule(function()
							require("diffview").open({ "-C" .. worktree_path, "origin/" .. base_ref .. "...HEAD", "--imply-local" })
						end)
					end)
				end)
			end

			-- headRefName/baseRefName are standard gh_pr item fields; fall back to gh if absent
			if item.headRefName and item.baseRefName then
				launch_diffview(item.headRefName, item.baseRefName)
			else
				vim.system(
					{ "gh", "pr", "view", pr_number, "--json", "headRefName,baseRefName", "--jq", "[.headRefName, .baseRefName] | @tsv" },
					{ text = true },
					function(r)
						if r.code ~= 0 then
							vim.schedule(function()
								vim.notify("[PR] Failed to get branch info for #" .. pr_number, vim.log.levels.ERROR)
							end)
							return
						end
						local head, base = vim.trim(r.stdout or ""):match("^(.+)\t(.+)$")
						if not head then
							vim.schedule(function()
								vim.notify("[PR] Could not parse branch info", vim.log.levels.ERROR)
							end)
							return
						end
						vim.schedule(function() launch_diffview(head, base) end)
					end
				)
			end
		end,
	})
end, { desc = "PR Open in Diffview (worktree)" })

set("n", "<leader>giD", function()
	Snacks.picker.gh_pr({
		confirm = function(picker, item)
			if not item then return end
			picker:close()

			local pr_number     = tostring(item.number)
			local worktree_dir  = vim.fn.stdpath("data") .. "/pr-worktrees"
			local worktree_path = worktree_dir .. "/pr-" .. pr_number

			local function open_claude()
				vim.notify("[PR] Opening Claude in worktree for #" .. pr_number, vim.log.levels.INFO)
				local prompt = string.format(
					"Review PR #%s. Run `gh pr view %s` first for context, then examine the changed files and give a thorough code review.",
					pr_number, pr_number
				)
				Snacks.terminal(
					{ "claude", prompt },
					{ id = "pr-claude-" .. pr_number, cwd = worktree_path, win = { position = "right" } }
				)
			end

			local function launch_claude(head_ref)
				vim.fn.mkdir(worktree_dir, "p")

				if vim.fn.isdirectory(worktree_path) == 1 then
					vim.notify("[PR] Reusing worktree for #" .. pr_number, vim.log.levels.INFO)
					open_claude()
					return
				end

				vim.notify("[PR] Fetching " .. head_ref .. "...", vim.log.levels.INFO)
				vim.system({ "git", "fetch", "origin", head_ref }, {}, function(r1)
					if r1.code ~= 0 then
						vim.schedule(function()
							vim.notify("[PR] fetch failed:\n" .. (r1.stderr or ""), vim.log.levels.ERROR)
						end)
						return
					end

					vim.system({ "git", "worktree", "add", "--detach", worktree_path, "origin/" .. head_ref }, {}, function(r2)
						if r2.code ~= 0 then
							vim.schedule(function()
								vim.notify("[PR] worktree add failed:\n" .. (r2.stderr or ""), vim.log.levels.ERROR)
							end)
							return
						end
						vim.schedule(open_claude)
					end)
				end)
			end

			if item.headRefName then
				launch_claude(item.headRefName)
			else
				vim.system(
					{ "gh", "pr", "view", pr_number, "--json", "headRefName", "--jq", ".headRefName" },
					{ text = true },
					function(r)
						if r.code ~= 0 then
							vim.schedule(function()
								vim.notify("[PR] Failed to get branch info for #" .. pr_number, vim.log.levels.ERROR)
							end)
							return
						end
						local head = vim.trim(r.stdout or "")
						if head == "" then
							vim.schedule(function()
								vim.notify("[PR] Could not parse branch info", vim.log.levels.ERROR)
							end)
							return
						end
						vim.schedule(function() launch_claude(head) end)
					end
				)
			end
		end,
	})
end, { desc = "PR Review with Claude (worktree)" })

-- LSP Pickers
set("n", "gpd", function() Snacks.picker.lsp_definitions() end, { desc = "Goto Definition" })
set("n", "gpD", function() Snacks.picker.lsp_declarations() end, { desc = "Goto Declaration" })
set("n", "gpr", function() Snacks.picker.lsp_references() end, { desc = "References", nowait = true })
set("n", "gpi", function() Snacks.picker.lsp_implementations() end, { desc = "Goto Implementation" })
set("n", "gpt", function() Snacks.picker.lsp_type_definitions() end, { desc = "Goto Type Definition" })
set("n", "gps", function() Snacks.picker.lsp_symbols() end, { desc = "LSP Symbols" })
set("n", "gpS", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "LSP Workspace Symbols" })

-- Terminal
set({ "n", "t" }, [[<c-\>]], function() Snacks.terminal.toggle() end, { desc = "Toggle Terminal (Snacks)" })

-- Notifications
set("n", "<leader>sN", function() Snacks.picker.notifications() end, { desc = "Notifications" })
set("n", "<leader>sn", function() Snacks.notifier.show_history() end, { desc = "Notification History" })

-- GitBrowse
set({ "n", "x" }, "<leader>go", function() Snacks.gitbrowse() end, { desc = "Git Browse (Open in Browser)" })
set("n", "<leader>gO", function() Snacks.gitbrowse({ what = "repo" }) end, { desc = "Git Browse (Repo Root)" })
set("n", "<leader>gc", function() Snacks.gitbrowse({ what = "commit" }) end, { desc = "Git Browse (Current Commit)" })
set({ "n", "x" }, "<leader>gy", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
      vim.notify("Copied: " .. url, vim.log.levels.INFO, { title = "Snacks Git Browse" })
    end,
    notify = false,
  })
end, { desc = "Git Browse (Copy Link)" })

-- ── Git / LazyGit ──────────────────────────────────────────────────────────────
-- Open LazyGit (Snacks auto-configures theme + nvim-remote integration)
set("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "LazyGit (Snacks)" })
-- or: set("n", "<leader>gg", function() Snacks.lazygit.open() end, { desc = "LazyGit (Snacks)" })

-- Open LazyGit's repository log view
set("n", "<leader>gL", function() Snacks.lazygit.log() end, { desc = "LazyGit Log (Repo)" })

-- Open LazyGit focused on the current file's log
set("n", "<leader>gF", function() Snacks.lazygit.log_file() end, { desc = "LazyGit Log (File)" })
