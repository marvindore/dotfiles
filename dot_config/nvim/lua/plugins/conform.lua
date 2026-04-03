vim.pack.add({
  {
    src = "https://github.com/stevearc/conform.nvim",
    data = {
      -- Lazy load when opening or creating a new buffer
      event = { "BufReadPre", "BufNewFile" },

      after = function(_)
        local conform = require("conform")

        conform.setup({
          formatters_by_ft = {
            cs = { "csharpier" },
            html = { "prettierd", "prettier", stop_after_first = true },
            lua = { "stylua" },
            python = { "isort", "black" },
            rust = { "rustfmt", lsp_format = "fallback" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            javascriptreact = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
            typescriptreact = { "prettierd", "prettier", stop_after_first = true },
          },
        })

        -- Format:
        --  - Normal mode: whole buffer
        --  - Visual mode: current selection (range auto-detected by conform)
        vim.keymap.set({ "n", "v" }, "<leader>F", function()
          local bufnr = vim.api.nvim_get_current_buf()
          local name = vim.api.nvim_buf_get_name(bufnr)

          local looks_like_template = name:match("%.tmpl$") or name:match("%.lua%.tmpl$")
          if not looks_like_template then
            local first_lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
            for _, line in ipairs(first_lines) do
              if line:find("{{", 1, true) then
                looks_like_template = true
                break
              end
            end
          end
          if looks_like_template then
            -- Use LSP formatting only (if your lua_ls can handle it)
            vim.lsp.buf.format({ async = false, timeout_ms = 1000 })
            return
          end

          -- Normal case: use Conform (stylua, etc.)
          require("conform").format({
            async = false,
            timeout_ms = 1000,

            -- IMPORTANT:
            -- "fallback" means "use LSP if no formatter exists",
            -- it does NOT mean "fallback if formatter fails". [4](https://github.com/stevearc/conform.nvim/issues/437)[5](https://deepwiki.com/stevearc/conform.nvim/3.3-lsp-integration)
            lsp_format = "fallback",
          })
        end, { desc = "Format file / selection (template-aware)" })
      end,
    },
  },
}, {
  -- Hand the data over to lze for lazy-loading
  load = function(p)
    local spec = p.spec.data or {}
    spec.name = p.spec.name
    require("lze").load(spec)
  end,
})
