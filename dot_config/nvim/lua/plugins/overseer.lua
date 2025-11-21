return {
  'stevearc/overseer.nvim',
  cmd = "OverseerOpen",
  config = function()
    require('overseer').setup()
  end
}
