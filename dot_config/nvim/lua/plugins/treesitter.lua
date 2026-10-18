-- ==========================================
-- Treesitter + Textobjects (Eager Load, Main API)
-- - Eager-load nvim-treesitter (main branch does not support lazy-loading)
-- - Parser list: lua/utils/ts_langs.lua
-- - Missing parsers are installed on startup (async) unless
--   g:ts_no_auto_install is set (the chezmoi headless bootstrap sets it and
--   waits on the install instead).
-- ==========================================

-- ------------------------------------------------
-- 1) Plugins (vim.pack + lze bridge)
-- ------------------------------------------------
local function setup_treesitter()
  -- Ensure the plugin's loader runs so :TSInstall/:TSUpdate exist.
  vim.cmd("packadd nvim-treesitter")
  require("nvim-treesitter").setup({})

  if not vim.g.ts_no_auto_install then
    vim.defer_fn(function() require("utils.ts_bootstrap").install_missing() end, 0)
  end

  -- Start Treesitter on FileType; set foldexpr from TS
  local aug = vim.api.nvim_create_augroup("treesitter_core_integration", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = "*",
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)

      if vim.bo[args.buf].buftype ~= "" then return end
      if vim.bo[args.buf].filetype == "minifiles" then return end

      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
    end,
  })
end

vim.pack.add({
  -- Core nvim-treesitter (EAGER; main branch)
  {
    src     = "https://github.com/nvim-treesitter/nvim-treesitter",
    name    = "nvim-treesitter",
    version = "main",
    data    = {
      build = ":TSUpdate",  -- run by the PackChanged hub after :PackUpdate
    },
  },

  -- Textobjects companion (new API on main)
  {
    src     = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    name    = "nvim-treesitter-textobjects",
    version = "main",
    data    = {
      after = function(_)
        pcall(function()
          require("nvim-treesitter-textobjects").setup({
            select = {
              enable = true,
              lookahead = true,
              selection_modes = {
                ["@parameter.outer"] = "v",
                ["@function.outer"]  = "V",
                ["@class.outer"]     = "<c-v>",
              },
              include_surrounding_whitespace = false,
            },
            move = { set_jumps = true },
            swap = {
              enable = true,
              swap_next     = { ["<leader>a"] = "@parameter.inner" },
              swap_previous = { ["<leader>A"] = "@parameter.inner" },
            },
          })
        end)
      end,
    },
  },

}, {
  -- ----- lze bridge loader -----
  load = function(p)
    local spec = p.spec
    local name = (spec.data and spec.data.name) or spec.name

    if name == "nvim-treesitter" then
      setup_treesitter()
      return
    end

    -- Other plugins: keep your existing loader behavior
    local data = spec.data or {}
    data.name = data.name or spec.name
    require("lze").load(data)
  end,
})

-- ------------------------------------------------
-- 2) Manual bootstrap command to install missing parsers
-- ------------------------------------------------
vim.api.nvim_create_user_command("TSBootstrap", function()
  if vim.fn.executable("tree-sitter") ~= 1 then
    vim.notify(
      "tree-sitter CLI not found. Install with `brew install tree-sitter-cli`.",
      vim.log.levels.WARN
    )
    return
  end
  local missing = require("utils.ts_bootstrap").missing()
  if #missing == 0 then
    vim.notify("All requested parsers already installed.", vim.log.levels.INFO)
    return
  end
  vim.notify("Installing parsers: " .. table.concat(missing, " "), vim.log.levels.INFO)
  require("nvim-treesitter").install(missing)
end, {})

-- ------------------------------------------------
-- 3) treesitter-context toggle mapping
-- ------------------------------------------------
vim.keymap.set("n", "<localleader>at", "<cmd>TSContextToggle<cr>", { desc = "Toggle Treesitter Context" })
