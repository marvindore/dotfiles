return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true },
    notify = { enabled = true },
    picker = { enabled = true,},
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
        indent = false
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
        indent = false
        }
      }
    },
  },
  keys = {
    { "<leader>bz", function() Snacks.zen.zoom() end, desc = "Toggle Zen Mode", mode = "n" },
    { "<leader>fs", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fF", function() Snacks.picker.files({ hidden = true }) end, desc = "Find Files" },
    { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.expand('%:p:h')}) end, desc = "Find File In Current Directory" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep Files" },
    { "<leader>fG", function() Snacks.picker.grep({ hidden = true }) end, desc = "Grep Hidden Files" },
    { "<leader>fe", function() Snacks.explorer() end, desc = "File Explorer" },
    { "<leader>fr", function() Snacks.picker.resume() end, desc = "Resume Find"},
    { "<leader>fj", function() Snacks.picker.jumps() end, desc = "Jumps"},
    { "<leader>fq", function() Snacks.picker.qflist() end, desc = "Jumps"},
    { "<S-h>", function() Snacks.picker.buffers() end, desc = "Buffers"},
    { "gpd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gpD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gpr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gpi", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gpt", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "gps", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "gpS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
    { "<leader>sN", function() Snacks.picker.notifications() end, desc = "Notifications" },
    { "<leader>sn", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>fm", function() Snacks.picker.marks() end, desc = "Marks" },
  }
}
