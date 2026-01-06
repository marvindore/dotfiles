vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions,globals"

return {
  "rmagatti/auto-session",
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/", "node_modules", "tmp", "*cache*", "~/.config", "~/.local" },
    bypass_save_filetypes = { "terminal" },
    bypass_session_save_file_types = { "terminal" }
    -- log_level = 'debug',
  },
}
