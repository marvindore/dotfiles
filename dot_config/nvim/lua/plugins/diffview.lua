vim.pack.add({
  "https://github.com/nvim-tree/nvim-web-devicons",
  {
    src = "https://github.com/dlyongemallo/diffview-plus.nvim",
    data = {
      cmd = {
        "DiffviewOpen",
        "DiffviewClose",
        "DiffviewToggle",
        "DiffviewFileHistory",
        "DiffviewFocusFiles",
        "DiffviewToggleFiles",
        "DiffviewRefresh",
      },
      on_require = { "diffview" },
      keys = {
        -- Toggle (open if closed, close if open)
        { lhs = "D",  rhs = ":DiffviewToggle<cr>",         mode = "n", desc = "Git Diff: Toggle" },

        -- Your other mappings
        { lhs = "<leader>dh", rhs = ":DiffviewFileHistory %<cr>",  mode = "n", desc = "Git File History" },
        { lhs = "<leader>dH", rhs = ":DiffviewFileHistory<cr>",    mode = "n", desc = "Git Repo History" },
        { lhs = "<leader>dc", rhs = ":DiffviewClose<cr>",          mode = "n", desc = "Git Close Diff" },
        { lhs = "<leader>dl", rhs = ":DiffviewOpen HEAD~1 -- %<cr>", mode = "n", desc = "Diff current file vs previous commit"}
      },

      after = function(_)
        ----------------------------------------------------------------------
        -- :DiffviewToggle that works from any Diffview buffer
        ----------------------------------------------------------------------
        vim.api.nvim_create_user_command("DiffviewToggle", function()
          local ft = vim.bo.filetype or ""
          if ft:match("^Diffview") then
            vim.cmd("DiffviewClose")
            return
          end

          local ok, lib = pcall(require, "diffview.lib")
          if ok and lib.get_current_view() then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end, {})

        ----------------------------------------------------------------------
        -- Remember the last focused *diff* window inside a Diffview tab.
        -- This makes hunk navigation predictable in diff2 / diff3 layouts.
        ----------------------------------------------------------------------
        vim.api.nvim_create_autocmd("WinEnter", {
          callback = function()
            local ok, lib = pcall(require, "diffview.lib")
            if not ok then return end
            local view = lib.get_current_view()
            if not view then return end
            if vim.wo.diff then
              vim.g.__dv_last_diff_win = vim.api.nvim_get_current_win()
            end
          end,
        })

        ----------------------------------------------------------------------
        -- Helpers: run ]c / [c in the diff window while staying in file panel
        ----------------------------------------------------------------------
        local function dv_send_hunk_jump(direction) -- "next" or "prev"
          -- Prefer the last diff window we saw in this Diffview tab
          local target = vim.g.__dv_last_diff_win
          if not (target and vim.api.nvim_win_is_valid(target) and
                  pcall(vim.api.nvim_win_get_option, target, "diff") and
                  vim.api.nvim_win_get_option(target, "diff")) then
            -- Fallback: find any diff window in this tab (excluding the file panel)
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if win ~= vim.api.nvim_get_current_win() then
                local ok_opt, is_diff = pcall(vim.api.nvim_win_get_option, win, "diff")
                if ok_opt and is_diff then
                  target = win
                  break
                end
              end
            end
          end

          if not (target and vim.api.nvim_win_is_valid(target)) then
            vim.notify("Diffview: no diff window found in this tab.", vim.log.levels.WARN)
            return
          end

          -- Execute ]c / [c in the diff window without moving focus
          vim.api.nvim_win_call(target, function()
            if direction == "next" then
              vim.cmd("normal! ]c")
            else
              vim.cmd("normal! [c")
            end
          end)
        end

        ----------------------------------------------------------------------
        -- Diffview setup + panel keymaps
        ----------------------------------------------------------------------
        local ok_dv, diffview     = pcall(require, "diffview")
        local ok_actions, actions = pcall(require, "diffview.actions")
        if ok_dv then
          diffview.setup({
            enhanced_diff_hl = true,
            view = {
              default    = { layout = "diff2_horizontal" },
              merge_tool = { layout = "diff4_mixed", disable_diagnostics = true },
            },
            hooks = {
              diff_buf_read = function(bufnr)
                -- change local options in buffer
                vim.opt_local.wrap = true
                vim.opt_local.linebreak = true
                vim.opt_local.breakindent = true
              end,
            },
            file_panel = {
              listing_style = "tree",
              win_config    = { position = "left", width = 35 },
            },
            keymaps = {
              view = {
                { "n", "e", actions.goto_file_split, { desc = "Edit file in split" } },
                { "n", "<leader>e", actions.goto_file, { desc = "Edit file (replace)" } },
              },

              -- File panel (left column)
              file_panel = {
                -- NEW: Navigate diff hunks in the diff window while staying here
                { "n", "]c", function() dv_send_hunk_jump("next") end, { desc = "Next hunk in diff" } },
                { "n", "[c", function() dv_send_hunk_jump("prev") end, { desc = "Prev hunk in diff" } },

                -- Keep D closing from the panel to avoid ref-picker
                { "n", "D", function() vim.cmd("DiffviewClose") end, { desc = "Close Diffview" } },

                -- (Optional) If you still want file-to-file stepping from the panel, you can
                -- add alt mappings like:
                -- { "n", "]f", ok_actions and actions.select_next_entry or function() require("diffview.actions").select_next_entry() end, { desc = "Next changed file" } },
                -- { "n", "[f", ok_actions and actions.select_prev_entry or function() require("diffview.actions").select_prev_entry() end, { desc = "Prev changed file" } },
              },

              -- File history panel: same hunk behavior
              file_history_panel = {
                { "n", "]c", function() dv_send_hunk_jump("next") end, { desc = "Next hunk in diff" } },
                { "n", "[c", function() dv_send_hunk_jump("prev") end, { desc = "Prev hunk in diff" } },
                { "n", "D", function() vim.cmd("DiffviewClose") end, { desc = "Close Diffview" } },
              },
            },
          })
        end

        -- Global safety net for the toggle (works everywhere)
        vim.keymap.set("n", "D", "<cmd>DiffviewToggle<cr>", {
          desc = "Git Diff: Toggle",
          silent = true,
          noremap = true,
        })

        -- Toggle wordwrap in diffview buffers
        vim.keymap.set("n", "<leader>cw", function()
          local ok, lib = pcall(require, "diffview.lib")
          if not ok then return end
          local view = lib.get_current_view()
          if not view then return end

          local new = not vim.wo.wrap
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_is_valid(win) then
              vim.wo[win].wrap = new
              vim.wo[win].linebreak = new
              vim.wo[win].breakindent = new
            end
          end
          vim.notify("Diffview: wrap " .. (new and "ON" or "OFF"), vim.log.levels.INFO, { title = "diffview" })
        end, { desc = "Diffview: toggle wrap (all panes)" })
      end,
    },
  },
}, {
  load = function(p)
    local spec = p.spec.data or {}
    spec.name = p.spec.name
    require("lze").load(spec)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "diff", "DiffviewFiles" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

-- showbreak (the dim "↳ " wrap marker) and breakindentopt are owned centrally
-- in settings.lua so there's a single source of truth; just ensure breakindent
-- is on here for diffview's own wrapped panes.
vim.opt.breakindent = true

