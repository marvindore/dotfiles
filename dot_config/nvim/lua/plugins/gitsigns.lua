return {
  'lewis6991/gitsigns.nvim',
  config = function()
    require('gitsigns').setup {
      gh = true,
    }
  end
}
