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

        -- conform's own range auto-detection (copied from vim.lsp.buf's
        -- range_from_selection) computes the END position as the LAST
        -- SELECTED CHARACTER, not one-past-it. LSP servers tolerate that,
        -- but CLI formatters that support range_args (stylua, prettier,
        -- prettierd) treat range-end as an exclusive byte offset, so the
        -- final byte of the selection is silently dropped. For a
        -- single-line or short selection this often means the enclosing
        -- statement looks "incomplete" to the formatter and nothing
        -- happens at all. Compute the range ourselves with the end column
        -- pushed one byte further to compensate.
        local function get_visual_range(bufnr)
          local mode = vim.api.nvim_get_mode().mode
          if mode ~= "v" and mode ~= "V" then
            return nil
          end

          local start = vim.fn.getpos("v")
          local end_ = vim.fn.getpos(".")
          local start_row, start_col = start[2], start[3]
          local end_row, end_col = end_[2], end_[3]

          if start_row == end_row and end_col < start_col then
            start_col, end_col = end_col, start_col
          elseif end_row < start_row then
            start_row, end_row = end_row, start_row
            start_col, end_col = end_col, start_col
          end

          if mode == "V" then
            start_col = 1
            local lines = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)
            end_col = #lines[1] + 1
          else
            end_col = end_col + 1
          end

          return {
            start = { start_row, start_col - 1 },
            ["end"] = { end_row, end_col - 1 },
          }
        end

        -- Format:
        --  - Normal mode: whole buffer
        --  - Visual mode: current selection
        vim.keymap.set({ "n", "v" }, "<leader>F", function()
          local bufnr = vim.api.nvim_get_current_buf()
          local name = vim.api.nvim_buf_get_name(bufnr)
          local range = get_visual_range(bufnr)

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
            -- Neovim's own range_from_selection matches the LSP convention,
            -- so pass it through unmodified here.
            vim.lsp.buf.format({ async = false, timeout_ms = 1000 })
            return
          end

          -- Normal case: use Conform (stylua, etc.)
          require("conform").format({
            async = false,
            timeout_ms = 1000,
            range = range,

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
