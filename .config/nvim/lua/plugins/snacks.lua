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
    picker = { enabled = false },
    quickfile = { enabled = true },
    zen = {
      enabled = true,
      toggles = {
        dim = true,
        git_signs = false,
        diagnostics = false,
        line_number = true,
        relative_number = true,
        indent = false
      },
    },
  },
  keys = {
    { "<leader>bz", function() Snacks.zen() end, desc = "Toggle Zen Mode", mode = "n" }
  }
}
