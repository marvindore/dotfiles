vim.g.current_os = vim.uv.os_uname().sysname:lower()
vim.g.enableCsharp = true
vim.g.enableGo = false
vim.g.enableJavascript = true
-- TS server: "auto" (tsc when the project's typescript >= 7, else vtsls), "tsc" (also use a
-- global TS 7 for older projects), or "vtsls". See lua/utils/ts_server.lua.
vim.g.tsLsp = "auto"
vim.g.enableJava = false
vim.g.enableKotlin = false
vim.g.enablePython = true
vim.g.enableRust = false
vim.g.enableSql = false
vim.g.isWindowsOs = vim.fn.has('win32') == 1
vim.g.homeDir = vim.g.isWindowsOs and os.getenv("USERPROFILE") or os.getenv('HOME')
vim.g.neovim_home = vim.g.isWindowsOs and vim.g.homeDir .. '/AppData/Local/nvim-data' or vim.g.homeDir .. '/.local/share/nvim'
vim.g.mason_root = vim.g.neovim_home .. "/mason"
vim.g.chezmoi_home = os.getenv("CHEZMOI_SOURCE_PATH") or (vim.g.homeDir .. "/.local/share/chezmoi")
-- Global variable to store REPL buffer
_G.repl_bufnr = nil
