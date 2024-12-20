return {
  'kevinhwang91/nvim-bqf',
  event = "VeryLazy",
  config = function()
    require('bqf').setup({})
  end
}
