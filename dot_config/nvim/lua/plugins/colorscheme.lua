vim.pack.add({
  { src = "https://github.com/webhooked/kanso.nvim.git"}
})

vim.opt.termguicolors = true
require("kanso").load("ink") -- zen, ink, mist, pearl
vim.cmd.colorscheme("kanso")
