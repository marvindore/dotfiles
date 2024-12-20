return {
  'windwp/nvim-autopairs',
  event = { "InsertEnter" },
  config = function()
    -- configure with completion nvim
    local Rule = require('nvim-autopairs.rule')
    local remap = vim.api.nvim_set_keymap
    local npairs = require('nvim-autopairs')

    -- skip it, if you use another global object
    _G.MUtils = {}

    MUtils.completion_confirm = function()
      if vim.fn.pumvisible() ~= 0 then
        return npairs.esc('<cr>')
      else
        return npairs.autopairs_cr()
      end
    end


    remap('i', '<CR>', 'v:lua.MUtils.completion_confirm()', { expr = true, noremap = true })

    -- Use treesitter to check for pairs
    npairs.setup({
      check_ts = true,
      ts_config = {
        lua = { 'string' }, -- it will not add pair on that treesitter node
        javascript = { 'template_string' },
        java = false,     -- don't check treesitter on java
      }
    })

    require('nvim-treesitter.configs').setup {
      autopairs = { enable = true }
    }

    local ts_conds = require('nvim-autopairs.ts-conds')


    -- press % => %% is only inside comment or string
    npairs.add_rules({
      Rule('%', '%', 'lua')
          :with_pair(ts_conds.is_ts_node({ 'string', 'comment' })),
      Rule('$', '$', 'lua')
          :with_pair(ts_conds.is_not_ts_node({ 'function' }))
    })
  end
}
