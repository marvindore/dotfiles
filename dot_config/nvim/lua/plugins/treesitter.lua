-- ==========================================
-- Treesitter + Textobjects + Context (Eager Load, Main API)
-- - Eager-load nvim-treesitter (main branch does not support lazy-loading)
-- - Install parsers ONLY when missing (Fix A)
-- - Includes a commented Fix B snippet (install only on PackChanged)
-- ==========================================

-- ------------------------------------------------
-- 0) Language list (with feature flags)
-- ------------------------------------------------
local install_list = {
  "bash",
  "cmake",
  "comment",
  "css",
  "cuda",
  "dockerfile",
  "gitignore",
  "graphql",
  "html",
  "http",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "latex",
  "lua",
  "make",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "scss",
  "sql",
  "svelte",
  "todotxt",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "vue",
  "yaml",
}

if vim.g.enableRust   then table.insert(install_list, "rust") end
if vim.g.enableJava   then vim.list_extend(install_list, { "java", "kotlin" }) end
if vim.g.enableCsharp then table.insert(install_list, "c_sharp") end
if vim.g.enableGo     then vim.list_extend(install_list, { "go", "gomod", "gowork" }) end

-- ------------------------------------------------
-- 1) Plugins (vim.pack + lze bridge)
-- ------------------------------------------------
vim.pack.add({
  -- Core nvim-treesitter (EAGER; main branch)
  {
    src     = "https://github.com/nvim-treesitter/nvim-treesitter",
    name    = "nvim-treesitter",
    version = "main",
    data    = {
      build = ":TSUpdate",  -- update parsers when plugin updates
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

  -- treesitter-context (UI add-on; safe to lazy by file events)
  {
    src  = "https://github.com/nvim-treesitter/nvim-treesitter-context",
    name = "nvim-treesitter-context",
    data = {
      event = { "BufReadPost", "BufNewFile" },
      after = function(_)
        require("treesitter-context").setup({
          enable = false,
          line_numbers = true,
          mode = "cursor",
          zindex = 20,
        })
      end,
    },
  },
}, {
  -- ----- lze bridge loader -----
  load = function(p)
    local spec = p.spec
    local name = (spec.data and spec.data.name) or spec.name

    if name == "nvim-treesitter" then
      -- Ensure the plugin's loader runs so :TSInstall/:TSUpdate exist.
      -- (pack: start packages auto-load, opt packages need :packadd)
      vim.cmd("packadd nvim-treesitter")  -- see :h pack and :h :packadd

      -- Main-branch API
      local ts = require("nvim-treesitter")
      ts.setup({}) -- optional (you can set install_dir here)

      -- ---- Fix A: install only missing parsers on startup ----
      local function missing_parsers(list)
        local missing = {}
        for _, lang in ipairs(list) do
          local so   = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so",   false)
          local wasm = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".wasm", false)
          if #so == 0 and #wasm == 0 then table.insert(missing, lang) end
        end
        return missing
      end

      vim.defer_fn(function()
        local miss = missing_parsers(install_list)
        if #miss > 0 then
          ts.install(miss)  -- async; no-op if all present
        end
      end, 0)

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

      --[[
      -------------------------------------------------------------------------
      Fix B (optional): install/update only when the plugin changes.
      Uncomment to use. This runs on :PackUpdate or initial install, and does
      nothing on normal startups (fastest steady state).

      vim.api.nvim_create_autocmd("PackChanged", {
        group = vim.api.nvim_create_augroup("ts_install_on_packchange", { clear = true }),
        pattern = "nvim-treesitter",
        callback = function(e)
          if e.data.kind == "install" or e.data.kind == "update" then
            require("nvim-treesitter").setup({})
            require("nvim-treesitter").install(install_list)
            -- Optionally also update existing parsers:
            -- require("nvim-treesitter").update()
          end
        end,
      })
      -------------------------------------------------------------------------
      ]]

      return
    end

    -- Other plugins: keep your existing loader behavior
    local data = spec.data or {}
    data.name = data.name or spec.name
    require("lze").load(data)
  end,
})

-- ------------------------------------------------
-- 2) One-shot bootstrap command to install missing parsers
-- ------------------------------------------------
-- Uses runtimepath to detect parser files instead of the legacy parsers module.
local function has_installed_parser(lang)
  local so   = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so",   false)
  local wasm = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".wasm", false)
  return (#so > 0) or (#wasm > 0)
end

local function get_missing_parsers(list)
  local missing = {}
  for _, lang in ipairs(list) do
    if not has_installed_parser(lang) then
      table.insert(missing, lang)
    end
  end
  return missing
end

vim.api.nvim_create_user_command("TSBootstrap", function()
  if vim.fn.executable("tree-sitter") ~= 1 then
    vim.notify(
      "tree-sitter CLI not found. Install with `brew install tree-sitter` or `npm i -g tree-sitter-cli`.",
      vim.log.levels.WARN
    )
    return
  end
  local missing = get_missing_parsers(install_list)
  if #missing == 0 then
    vim.notify("All requested parsers already installed.", vim.log.levels.INFO)
    return
  end
  vim.cmd("TSInstall " .. table.concat(missing, " "))
end, {})

-- ------------------------------------------------
-- 3) treesitter-context toggle mapping
-- ------------------------------------------------
vim.keymap.set("n", "<localleader>at", "<cmd>TSContextToggle<cr>", { desc = "Toggle Treesitter Context" })
