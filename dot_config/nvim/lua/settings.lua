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
vim.schedule(function()
    opt.clipboard = 'unnamedplus'
end)
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

-----------------------------------------------------------------------
-- Wrapped prose/text settings for Neovim
--
-- Put this in:
--   init.lua
-- or a separate Lua file like:
--   lua/config/wrapping.lua
-- and require it from your init.lua
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Create an augroup so these autocmds are easy to manage/reload
-- without duplicating them if you source your config again.
-----------------------------------------------------------------------
local wrap_group = vim.api.nvim_create_augroup("WrapSettings", { clear = true })

-----------------------------------------------------------------------
-- Git commit messages
--
-- Why:
-- - Enable wrapping for easier writing in commit buffers
-- - Wrap at word boundaries (linebreak = true)
-- - Keep wrapped lines visually indented (breakindent = true)
-- - Show a small marker at wrapped screen lines (showbreak)
-- - Hard-wrap at 72 characters (textwidth = 72)
-- - Show a visual guide at column 73 (colorcolumn = "73")
-----------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = wrap_group,
  pattern = { "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.showbreak = "↪ "
    vim.opt_local.textwidth = 72
    vim.opt_local.colorcolumn = "73"
  end,
})

-----------------------------------------------------------------------
-- Markdown / plain text / reStructuredText / AsciiDoc
--
-- Why:
-- - Enable wrapping for long-form writing
-- - Wrap on word boundaries instead of splitting words
-- - Preserve indentation visually on wrapped lines
-- - Show a continuation marker for wrapped screen lines
-- - Hard-wrap at 80 characters
-- - Show a visual ruler just past the target width
-----------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = wrap_group,
  pattern = { "markdown", "text", "rst", "asciidoc" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.showbreak = "↪ "
    vim.opt_local.textwidth = 80
    vim.opt_local.colorcolumn = "81"
  end,
})

-----------------------------------------------------------------------
-- Better movement on wrapped lines
--
-- Why:
-- - In wrapped text, normal j/k move by file lines
-- - gj/gk move by screen lines
-- - This mapping makes j/k behave like gj/gk ONLY when no count is used
-- - If you type 5j or 3k, it still behaves like normal j/k
--
-- Result:
-- - j / k feels natural in wrapped prose
-- - counts still work exactly as expected
-----------------------------------------------------------------------
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", {
  expr = true,
  silent = true,
  desc = "Move by screen line when no count is given",
})

vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", {
  expr = true,
  silent = true,
  desc = "Move by screen line when no count is given",
})

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
-- Highlights
vim.cmd([[highlight WinBar1 guifg=LightBlue]])
vim.cmd([[highlight WinBar2 guifg=LightGreen]])

-- Get path for winbar; replace $HOME with ~; handle non-file buffers gracefully
local function get_winbar_path()
  local full_path = vim.fn.expand("%:p")
  if full_path == "" then
    -- Non-file buffer (help, quickfix, etc.)
    return "[No Name]"
  end
  return full_path:gsub(vim.fn.expand("$HOME"), "~")
end

-- Count buffers like :ls (listed buffers)
local function get_buffer_count()
  return #vim.fn.getbufinfo({ buflisted = 1 })
end
-- If you prefer only normal "file" buffers, use:
--[[
local function get_buffer_count()
  local count = 0
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if vim.bo[info.bufnr].buftype == '' then
      count = count + 1
    end
  end
  return count
end
]]

-- Winbar updater
local function update_winbar()
  local buffer_count = get_buffer_count()
  -- Use %{expr} so Neovim evaluates the path per-window at render time,
  -- not once as a hardcoded string applied globally via vim.opt.winbar.
  vim.opt.winbar = "%#WinBar1#%m "
    .. "%#WinBar2#("
    .. buffer_count
    .. ") "
    .. "%#WinBar1#%{expand('%:~')}"
    .. "%*%=%#WinBar2#"
end

-- Update on common lifecycle events
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "BufWipeout", "WinEnter", "TabEnter" }, {
  callback = update_winbar,
})

-- Exit insert mode when Neovim loses focus (e.g. switching workspaces via AeroSpace).
-- Without this, a fast workspace switch can leave you in insert mode when you return.
vim.api.nvim_create_autocmd("FocusLost", {
  callback = function() vim.cmd("stopinsert") end,
})

-- After startup (e.g., after session restore), schedule one more update
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(update_winbar, 50)
  end,
})

-- If your auto-session emits a post-restore event, hook it as well (safe no-op otherwise)
vim.api.nvim_create_autocmd("User", {
  pattern = "AutoSessionRestorePost",
  callback = function()
    vim.defer_fn(update_winbar, 10)
  end,
})
-- end buffer count

-- Python
-- Don't run this on startup. Run it only when a python file is opened.
local function set_python_host_prog()
    local cwd = vim.fn.getcwd()
    local venv_paths = { cwd .. "/.venv/bin/python3", cwd .. "/venv/bin/python" }
    
    for _, path in ipairs(venv_paths) do
        if vim.fn.filereadable(path) == 1 then
            vim.g.python3_host_prog = path
            return
        end
    end
    vim.g.python3_host_prog = vim.g.neovim_home .. "/mason/packages/debugpy/venv/bin/python3"
end

local last_notified_python_host_prog

vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        set_python_host_prog()
        local python_host_prog = vim.g.python3_host_prog or "system"
        if python_host_prog == last_notified_python_host_prog then
            return
        end

        last_notified_python_host_prog = python_host_prog
        vim.notify("Using python: " .. python_host_prog, vim.log.levels.INFO, {
            title = "Python",
            timeout = 3000,
        })
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
