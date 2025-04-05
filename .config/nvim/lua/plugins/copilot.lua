return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  enabled = vim.g.enableCopilot,
  dependencies = {
    "zbirenbaum/copilot-cmp"
  },
  config = function()
    require("copilot").setup({
      suggestion = {
        enabled = true,
        auto_trigger = false,
      },
      panel = { enabled = false },
    })
    require("copilot_cmp").setup()
  end,
}
