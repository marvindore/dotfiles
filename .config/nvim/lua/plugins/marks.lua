return {
  'chentoast/marks.nvim',
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require('marks').setup({})
  end
}
