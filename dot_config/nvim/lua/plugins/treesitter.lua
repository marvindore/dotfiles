return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  event = { "BufReadPost", "BufNewFile" },
  opts = { highlight = { enable = true } },
  config = function()
    require 'nvim-treesitter.configs'.setup {
      configs = {
        ignore_install = { "help", "vimdoc" }
      },
      modules = {},
      ignore_install = { "help" },
      ensure_installed = {
        'bash',
        'c_sharp',
        'cmake',
        'comment',
        --'cpp',
        'css',
        'cuda',
        --'devicetree',
        'dockerfile',
        'gitignore',
        'go',
        --'gomod',
        --'gowork',
        'graphql',
        'html',
        'http',
        'java',
        'javascript',
        'jsdoc',
        'json',
        'json5',
        --'jsonnet',
        'julia',
        'kotlin',
        'latex',
        'lua',
        'make',
        'markdown',
        'markdown_inline',
        --'ocaml',
        --'ocaml_interface',
        --'ocamllex',
        'php',
        'phpdoc',
        'python',
        'query',
        'tlaplus',
        'regex',
        'rust',
        'scala',
        --'scheme,'
        'scss',
        --'solidity',
        'sql',
        'svelte',
        --'swift',
        'todotxt',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'vue',
        'yaml',
        --'zig'
      }, -- one of 'all', 'maintained' (parsers with maintainers), or a list of languages
      sync_install = false,
      auto_install = true,
      highlight = {
        enable = true,             -- false will disable the whole extension
        disable = { 'c', 'rust' }, -- list of language that will be disabled
      },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<c-space>',
          node_incremental = '<c-space>',
          scope_incremental = '<c-s>',
          node_decremental = '<c-backspace>',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            [']m'] = '@function.outer',
            [']]'] = '@class.outer',
          },
          goto_next_end = {
            [']M'] = '@function.outer',
            [']['] = '@class.outer',
          },
          goto_previous_start = {
            ['[m'] = '@function.outer',
            ['[['] = '@class.outer',
          },
          goto_previous_end = {
            ['[M'] = '@function.outer',
            ['[]'] = '@class.outer',
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ['<leader>a'] = '@parameter.inner',
          },
          swap_previous = {
            ['<leader>A'] = '@parameter.inner',
          },
        },
      },
    }
  end
}
