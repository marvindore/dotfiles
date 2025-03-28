local utils = require("utils")
return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  enabled = utils.enableCopilot,
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
