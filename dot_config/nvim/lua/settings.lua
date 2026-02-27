-- General settings
local wo = vim.wo
local g = vim.g
local opt = vim.opt

vim.g.lazyvim_picker = "snacks"

opt.autoread = false -- potentially help prevent neovim freezes
vim.cmd("set modifiable")
-- Colorscheme
vim.cmd("hi Cursor guibg=green")
vim.cmd [[
hi DiagnosticUnderlineError guisp='Red' gui=underline
hi DiagnosticUnderlineWarn guisp='Cyan' gui=undercurl
]]
-- spell checker
opt.spelllang = 'en_us'
opt.spell = false -- disable by default

-- diagnostics
vim.diagnostic.config({ virtual_lines = { current_line = true } })

--vim.cmd[[set guicursor=n-v-c-i:block]]
-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- disable language provider support for languages (lua and vimscript plugins only)
-- vim.g.loaded_perl_provider = 0
-- vim.g.loaded_ruby_provider = 0

vim.cmd[[filetype plugin on]]

--opt.inccommand = "split"

--Editor
opt.backup = false
opt.wrap = false
opt.encoding = 'utf-8'
opt.fileencoding = 'utf-8' -- The encoding written to file
--opt.termencoding = 'utf-8'
vim.o.hidden = true -- Required to keep multiple buffers open multiple buffers
--vim.wo.wrap = false -- Display long lines as just one line
--vim.cmd('syntax on') -- move to next line with theses keys
vim.o.pumheight = 10 -- Makes popup menu smaller
vim.o.cmdheight = 2 -- More space for displaying messages
vim.o.mouse = 'a' -- Enable your mouse
vim.o.splitbelow = true -- Horizontal splits will automatically be below
vim.o.conceallevel = 0 -- So that I can see `` in markdown files
--vim.o.timeoutlen = 100 -- By default timeoutlen is 1000 ms, this causes leader key not to work
vim.o.clipboard = 'unnamedplus' -- Copy paste between vim and everything else
vim.cmd[[ set dir=~/neovim/swaps ]]

-- keep folding enabled but don't fold all lines by default
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

vim.opt.tabstop=4
vim.opt.shiftwidth=4
vim.opt.softtabstop=4
vim.opt.expandtab=true
vim.opt.smarttab=true
vim.opt.copyindent=true

-- highlight color
--vim.cmd[[ set nowrap ]]
vim.cmd[[ set colorcolumn=80,120 ]]
--vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg=0, bg=LightGrey })
--vim.api.nvim_set_hl(0, "Normal", { ctermfg=White,  ctermbg=Black })

--vim.cmd[[ let g:vimwiki_list = \[{'path':'~/vimwiki', 'syntax': 'markdown', 'ext': '.md'}\] ]]
--vim.cmd[[ let g:vimwiki_ext2syntax = {'.md':'markdown', '.markdown': 'markdown', '.mdown': 'markdown'} ]]

vim.g.vimwiki_markdown_link_ext = 1
vim.g.wildmenu=true
vim.o.sidescrolloff=7
vim.o.hlsearch=true
vim.o.splitright=true
vim.o.splitbelow=true
vim.o.cursorline=true

vim.o.showcmd=true
vim.g.syntax=true
vim.wo.number=true
vim.wo.relativenumber=true
vim.wo.numberwidth=2
vim.o.scrolloff=7
vim.g.noswapfile=true

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Decrease update time
--vim.o.updatetime = 250 -- might be causing nvim freezing
vim.wo.signcolumn = 'yes'

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- Copilot
vim.api.nvim_set_hl(0, "CmpItemKindCopilot", {fg ="#6CC644"})

-- Identify white space
-- vim.cmd([[
-- set list listchars=tab:»\ ,trail:·,nbsp:⎵,precedes:<,extends:>
-- ]])

-- Delte white space
-- vim.api.nvim_create_autocmd({ "BufWritePre" }, {
--   pattern = { "*" },
--   command = [[%s/\s\+$//e]],
-- })

if vim.fn.has('termguicolors') == 1 then
    vim.api.nvim_command('set termguicolors')
end


-- Windows Settings
if vim.fn.has('win32') == 1 then
  vim.g.sqlite_clib_path = 'C:/sqlite3.dll'
  vim.cmd[[let &shell = executable('pwsh') ? 'pwsh' : 'powershell']]

  local powershell_options = {
  shell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell",
  shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
  shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
  shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
  shellquote = "",
  shellxquote = "",
  }

  for option, value in pairs(powershell_options) do
    vim.opt[option] = value
  end
end

-- Set buffer count
vim.cmd([[highlight WinBar1 guifg=LightBlue]])
vim.cmd([[highlight WinBar2 guifg=LightGreen]])
-- Function to get the full path and replace the home directory with ~
local function get_winbar_path()
  local full_path = vim.fn.expand("%:p")
  return full_path:gsub(vim.fn.expand("$HOME"), "~")
end
-- Function to get the number of open buffers using the :ls command
local function get_buffer_count()
  local buffers = vim.fn.execute("ls")
  local count = 0
  -- Match only lines that represent buffers, typically starting with a number followed by a space
  for line in string.gmatch(buffers, "[^\r\n]+") do
    if string.match(line, "^%s*%d+") then
      count = count + 1
    end
  end
  return count
end
-- Function to update the winbar
local function update_winbar()
  local home_replaced = get_winbar_path()
  local buffer_count = get_buffer_count()
  vim.opt.winbar = "%#WinBar1#%m "
    .. "%#WinBar2#("
    .. buffer_count
    .. ") "
    .. "%#WinBar1#"
    .. home_replaced
    .. "%*%=%#WinBar2#"
  -- I don't need the hostname as I have it in lualine
  -- .. vim.fn.systemlist("hostname")[1]
end
-- Autocmd to update the winbar on BufEnter and WinEnter events
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  callback = update_winbar,
})


-- Python
local function set_python_host_prog()
  local buf_ft = vim.bo.filetype
  --if buf_ft ~= "python" then return end

  local cwd = vim.fn.getcwd()
  local venv_paths = {
    cwd .. "/.venv/bin/python3",
    cwd .. "/venv/bin/python",
    cwd .. "/env/bin/python"
  }

  for _, path in ipairs(venv_paths) do
    if vim.fn.filereadable(path) == 1 then
      vim.g.python3_host_prog = path
      --print("Using virtualenv Python: " .. path)

      -- Update system $PATH if necessary
      -- local venv_bin = vim.fn.fnamemodify(path, ":h") -- get the bin directory
      -- local current_path = vim.fn.getenv("PATH")
      -- local path_parts = vim.split(current_path, ":", { plain = true })
      --
      -- if path_parts[1] ~= venv_bin then
      --   table.insert(path_parts, 1, venv_bin)
      --   local new_path = table.concat(path_parts, ":")
      --   vim.fn.setenv("PATH", new_path)
      --   print("Prepended venv bin to PATH: " .. venv_bin)
      -- end

      return
    end
  end

  -- Fallback to system Python
  vim.g.python3_host_prog = vim.g.neovim_home .. "/mason/packages/debugpy/venv/bin/python3"
  --print("Using system Python: " .. vim.g.python3_host_prog)
end

set_python_host_prog()

-- Autocommand to trigger the function when a Python file is opened
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    print("Using python: " .. vim.g.python3_host_prog)
  end,
})


-- Prevent lsp and other pluggins from attaching to repl buffers
vim.api.nvim_create_autocmd("FileType", {
  pattern = "dap-repl",
  callback = function()
    vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dap-repl",
  callback = function()
    vim.b.copilot_enabled = false
  end,
})
