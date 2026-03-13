---------------------------------------
-- 1) Safer sessionoptions
---------------------------------------
-- Avoid 'globals' to prevent state corruption across sessions.
-- Also avoid restoring exact window positions/tabs unless you really need it. No `globals`
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,winsize,terminal,localoptions,globals"


---------------------------------------
-- 2) auto-session setup (don’t persist volatile UIs)
---------------------------------------
vim.pack.add({
  "https://github.com/rmagatti/auto-session",
})

require("auto-session").setup({
  suppressed_dirs = {
    "~/",
    "~/Projects",
    "~/Downloads",
    "/",
    "node_modules",
    "tmp",
    "*cache*",
    "~/.config",
    "~/.local",
  },

  -- Do not save/restore volatile UI buffers (DAP, Trouble, Neotest, etc.)
  bypass_save_filetypes = {
    "terminal",
    "dap-repl",
    "dapui_watches",
    "dapui_breakpoints",
    "dapui_scopes",
    "dapui_console",
    "trouble",
    "neotest-summary",
    "neotest-output",
    "neotest-output-panel",
    "neotest-attach",
    -- If codediff uses a custom filetype, add it here (e.g., "codediff")
  },

  -- Some versions of auto-session recognize this alias; harmless if ignored.
  bypass_session_save_file_types = {
    "terminal",
    "dap-repl",
    "dapui_watches",
    "dapui_breakpoints",
    "dapui_scopes",
    "dapui_console",
    "trouble",
    "neotest-summary",
    "neotest-output",
    "neotest-output-panel",
    "neotest-attach",
    -- "codediff",
  },

  -- Proactively close volatile panels right before saving a session.
  pre_save_cmds = {
    function()
      -- Close Neotest panels if present
      pcall(function()
        local neotest = require("neotest")
        if neotest.summary and neotest.summary.is_open() then neotest.summary.close() end
        if neotest.output_panel and neotest.output_panel.is_open() then neotest.output_panel.close() end
      end)
      -- Close DAP UI if it exists
      pcall(function()
        local dapui = require("dapui")
        dapui.close()
      end)
      -- Close Trouble if it exists
      pcall(function()
        vim.cmd("TroubleClose")
      end)
      -- If codediff exposes a close command, try it (safe if it doesn't exist)
      pcall(function()
        vim.cmd("CodeDiffClose")
      end)
    end,
  },

  auto_restore_enabled = true,
  auto_save_enabled = true,
})

