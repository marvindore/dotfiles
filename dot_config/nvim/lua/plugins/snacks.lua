-- 1) Add the plugin natively (clones the source)
vim.pack.add({
  "https://github.com/folke/snacks.nvim",
})

-- 2) Configuration Setup
local opts = {
  bigfile  = { enabled = true },
  lazygit  = { enabled = true }, -- Snacks' LazyGit module
  notifier = { enabled = true },
  notify   = { enabled = true },
  picker   = { enabled = true, opts = { formatters = { truncate = false } } },
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

-- 4) Keymaps (Standard Vim keymap API for eager loading)
local set = vim.keymap.set

-- Zen & Utilities
set("n", "<leader>bz", function() Snacks.zen.zoom() end, { desc = "Toggle Zen Mode" })
set("n", "<leader>fe", function() Snacks.explorer() end, { desc = "File Explorer" })

-- Finders
set("n", "<leader>fs", function() Snacks.picker.smart() end, { desc = "Smart Find Files" })
set("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find Files" })
set("n", "<leader>fF", function() Snacks.picker.files({ hidden = true }) end, { desc = "Find Hidden Files" })
set("n", "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.expand("%:p:h") }) end, { desc = "Find File In Current Dir" })
set("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Grep Files" })
set("n", "<leader>fG", function() Snacks.picker.grep({ hidden = true }) end, { desc = "Grep Hidden Files" })
set("n", "<leader>fr", function() Snacks.picker.resume() end, { desc = "Resume Find" })
set("n", "<leader>fj", function() Snacks.picker.jumps() end, { desc = "Jumps" })
set("n", "<leader>fq", function() Snacks.picker.qflist() end, { desc = "Quickfix List" })
set("n", "<S-h>", function() Snacks.picker.buffers() end, { desc = "Buffers" })
set("n", "<leader>fm", function() Snacks.picker.marks() end, { desc = "Marks" })

-- LSP Pickers
set("n", "gpd", function() Snacks.picker.lsp_definitions() end, { desc = "Goto Definition" })
set("n", "gpD", function() Snacks.picker.lsp_declarations() end, { desc = "Goto Declaration" })
set("n", "gpr", function() Snacks.picker.lsp_references() end, { desc = "References", nowait = true })
set("n", "gpi", function() Snacks.picker.lsp_implementations() end, { desc = "Goto Implementation" })
set("n", "gpt", function() Snacks.picker.lsp_type_definitions() end, { desc = "Goto Type Definition" })
set("n", "gps", function() Snacks.picker.lsp_symbols() end, { desc = "LSP Symbols" })
set("n", "gpS", function() Snacks.picker.lsp_workspace_symbols() end, { desc = "LSP Workspace Symbols" })

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
