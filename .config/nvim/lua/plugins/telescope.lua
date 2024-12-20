return {
  {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  cmd = 'Telescope',
  dependencies = {
    'nvim-lua/plenary.nvim'
  },
  config = function()
    -- local builtin = require("telescope.builtin")
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")

    --require'telescope'.load_extension('project')

    telescope.setup {

      defaults = {
        mappings = {
          i = {
            ["<C-l>"] = actions.cycle_previewers_next,
            ["<C-h>"] = actions.cycle_previewers_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-w>"] = actions.send_selected_to_qflist,
            ["<C-q>"] = actions.send_to_qflist,
          },
          n = {
            ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
            ["<s-tab>"] = actions.toggle_selection + actions.move_selection_previous,
            ["<C-w>"] = actions.send_selected_to_qflist,
            ["<C-q>"] = actions.send_to_qflist,
            ["d"] = actions.delete_buffer,
            ["q"] = actions.close
          }
        },
        dynamic_preview_title = true,
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case'
        },
        prompt_prefix = '> ',
        selection_caret = '> ',
        entry_prefix = '  ',
        initial_mode = 'insert',
        selection_strategy = 'reset',
        sorting_strategy = 'descending',
        layout_strategy = 'horizontal',
        file_sorter = require 'telescope.sorters'.get_fuzzy_file,
        file_ignore_patterns = {},
        generic_sorter = require 'telescope.sorters'.get_generic_fuzzy_sorter,
        path_display = { 'shorten' },
        winblend = 0,
        layout_config = {
          horizontal = {
            mirror = false,
          },
          vertical = {
            mirror = false,
          },
          width = 0.8,
          prompt_position = 'top',
          preview_cutoff = 120,
          height = 0.8,
        },
        border = {},
        borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
        color_devicons = true,
        use_less = true,
        set_env = { ['COLORTERM'] = 'truecolor' }, -- default = nil,
        file_previewer = require 'telescope.previewers'.vim_buffer_cat.new,
        grep_previewer = require 'telescope.previewers'.vim_buffer_vimgrep.new,
        qflist_previewer = require 'telescope.previewers'.vim_buffer_qflist.new,

        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = require 'telescope.previewers'.buffer_previewer_maker
      },
      -- You dont need to set any of these options. These are the default ones. Only
      -- the loading is important
      extensions = {
        fzf = {
          fuzzy = true,               -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case",   -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        }
      }
    }

    -- Enable telescope fzf native, if installed
    pcall(require('telescope').load_extension, 'fzf')

    -- builtin.find_files({
    --         -- use fd to "find files" and return absolute paths
    --   find_command = { "fd", "-t=f", "-a" },
    --   path_display = { "absolute" },
    --         wrap_results = true
    -- })
  end
},
  {
    "nvim-telescope/telescope-project.nvim",
    dependencies = "nvim-telescope/telescope.nvim"
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    dependencies = "nvim-telescope/telescope.nvim",
    config = function()
      require("telescope").load_extension("ui-select")
    end
  }
}
