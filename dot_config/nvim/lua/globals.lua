local current_os = vim.loop.os_uname().sysname:lower()

vim.g.enableJavascript = true
vim.g.enableJava = false
vim.g.enableKotlin = false
vim.g.enableCsharp = false
vim.g.enableGo = false
vim.g.enablePython = true
vim.g.enableRust = false
vim.g.enableAvante = false
vim.g.enableCodeCompanion = true
vim.g.enableCopilot = false
vim.g.isWindowsOs = vim.fn.has('win32') == 1
vim.g.homeDir = vim.g.isWindowsOs and os.getenv("USERPROFILE") or os.getenv('HOME')
vim.g.neovim_home = vim.g.isWindowsOs and vim.g.homeDir .. '/AppData/Local/nvim-data' or vim.g.homeDir .. '/.local/share/nvim'
vim.g.mason_root = vim.g.neovim_home .. "/mason"

-- Global variable to store REPL buffer
_G.repl_bufnr = nil
