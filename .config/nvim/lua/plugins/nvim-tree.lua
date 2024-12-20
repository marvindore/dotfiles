return {
  'nvim-tree/nvim-tree.lua',
  event = "VeryLazy",
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- optional, for file icons
  },
  config = function()
    -- disable netrw at the very start of your init.lua (strongly advised)
    vim.g.loaded = 1
    vim.g.loaded_netrwPlugin = 1
    vim.opt.termguicolors = true

    -- OR setup with some options
    require("nvim-tree").setup({
      sort_by = "case_sensitive",
      -- on_attach = on_attach,
      view = {
        adaptive_size = true,
        width = 35,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
      update_focused_file = {
        enable = true,
        update_root = false,
        ignore_list = {},
      },
      modified = {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
      },
      git = {
        enable = true,
        ignore = true,
        timeout = 500,
      },
    })
  end
}
