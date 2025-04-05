return {
  "j-hui/fidget.nvim",
  tag = "v1.6.1",
  event = "LspAttach",
  config = function()
    require('fidget').setup()
  end,
  opts = {
    -- options
  },
}
