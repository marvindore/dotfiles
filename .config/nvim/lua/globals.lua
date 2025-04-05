local current_os = vim.loop.os_uname().sysname:lower()

vim.g.enableJavascript = true
vim.g.enableJava = false
vim.g.enableCsharp = false
vim.g.enableGo = true
vim.g.enablePython = true
vim.g.enableAvante = false
vim.g.enableCopilot = false
vim.g.enableCodeium = false
vim.g.isWindowsOs = vim.fn.has('win32') == 1
vim.g.homeDir = vim.g.isWindows and os.getenv("USERPROFILE") or os.getenv('HOME')
vim.g.neovim_home = vim.g.isWindows and vim.g.homeDir .. '/AppData/Local/nvim-data' or vim.g.homeDir .. '/.local/share/nvim'
