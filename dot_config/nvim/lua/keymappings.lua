-- variables
local wk = require("which-key")

local map = function(mode, keys, func, desc)
	if not desc then
		desc = "Not Set"
	end
	vim.keymap.set(mode, keys, func, { silent = true, desc = "K: " .. desc })
end

-- Escape termcodes
local function t(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- set pwd with cd %%
vim.keymap.set("c", "%%", function()
	if vim.fn.getcmdtype() == ":" then
		return vim.fn.expand("%:h") .. "/"
	else
		return "%%"
	end
end, { expr = true })

--map("n", "<Space>", "<NOP>", )

-- Format on all files not just LSP
map(
	"n",
	"<leader>F",
	":lua require('conform').format({ lsp_fallback = true, async = false, timeout_ms= 1000})<CR>",
	"Format"
)

map("n", "<leader>W", ":WhichKey<cr>", "Which Key")

-- LSP config
vim.api.nvim_create_user_command("LspInfo", function()
  -- convert clients table to string
  local lines = vim.split(vim.inspect(vim.lsp.get_clients()), "\n")

  -- create a new scratch buffer
  vim.cmd("tabnew")  -- optional: open in new tab
  local bufnr = vim.api.nvim_get_current_buf()

  -- set buffer options
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

  -- set lines
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- optionally set filetype for syntax highlighting
  vim.api.nvim_buf_set_option(bufnr, "filetype", "lua")
end, {})


vim.api.nvim_create_user_command("LspInfoBuf", function()
  vim.print(vim.lsp.get_clients({ bufnr = 0 }))
end, {})

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd('edit ' .. vim.lsp.get_log_path())
end, {})

vim.api.nvim_create_user_command("LspRestartAll", function()
  for _, client in ipairs(vim.lsp.get_clients()) do
    client.stop(true)
  end
end, {})

vim.api.nvim_create_user_command("LspRestart", function()
  local bufnr = vim.api.nvim_get_current_buf()

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    client.stop(true)
  end

  -- force reattach
  vim.cmd("edit")
end, {})

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "<leader><space>", "<C-^>", "Go to previous buffer")
map("n", "<leader>bd", ":bdelete<cr>", "Buffer Delete")
map("n", "<leader>bD", ":bdelete!<cr>", "Buffer Force Delete")
map("n", "<leader>bq", ":%bd|e #<cr>", "Buffer Delete All Other Buffers")

-- Allow gf to open non-existent files
map("n", "gf", ":edit <cfile><CR>", "Open filename under cursor")

-- better window movement
-- map("n", "<C-h>", "<C-w>h", "Switch window left")
-- map("n", "<C-j>", "<C-w>j", "Switch window down")
-- map("n", "<C-k>", "<C-w>k", "Swith window up")
-- map("n", "<C-l>", "<C-w>l", "Switch window right")

-- Clear search
vim.api.nvim_create_user_command("C", 'let @/=""', {})

-- Copy and paste
map("v", "<C-c>", '"+yi', "Copy global")
map("v", "<C-x>", '"+c', "Cut global")
map("v", "<C-v>", 'c<ESC>"+p', "Paste global")
map("v", "<C-V>", '<ESC>"+pa', "Paste no copy")

-- Wrap selection
map("v", ",b", [[c{ <c-r>" }<esc>]], "Wrap in curly braces") -- surround curly braces
map("v", ",B", [[c[<c-r>"]<esc>]], "Wrap in square brackets") -- surround square brackets
map("v", ",t", [[c`<c-r>"`<esc>]], "Wrap in back ticks") -- surround back ticks
map("v", ",s", [[c <c-r>" <esc>]], "Wrap in single space") -- surround single space
map("v", ",q", [[c'<c-r>"'<esc>]], "Wrap in single quotes") -- surround single quotes
map("v", ",Q", [[c"<c-r>""<esc>]], "Wrap in double quotes") -- surround double quotes
map("v", ",p", [[c(<c-r>")<esc>]], "Wrap in single parentheses") -- surround single parentheses


-- Move while insert mode
map("i", "<C-l>", "<Right>", "Move right")
map("i", "<C-h>", "<Left>", "Move left")
map("i", "<C-j>", "<Down>", "Move down")
map("i", "<C-k>", "<Up>", "Move up")

-- Moving to start or end of line (insert mode)
-- <C-o> switches vim to insert mode for one command
map("i", t("<C-e>"), "<C-o>$", "")
map("i", t("<C-a>"), "<C-o>0", "")

-- Scroll
map("n", "<S-left>", "10zh", "")
map("n", "<S-right>", "10zl", "")


function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	vim.keymap.set("t", "<esc>", [[<C-\><C-n>]])
	vim.keymap.set("t", "jk", [[<C-\><C-n>]])
	vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]])
	vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]])
	vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]])
	vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]])
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead of term://*
vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")

-- Iron Repl
wk.add({
	{ "<leader>r", group = "Repl" },
})
map("n", "<leader>rr", ":IronRepl<cr>", "Repl toggle")
map("n", "<leader>rt", ":IronRestart<cr>", "Repl toggle")
--map("n", "<leader>rc", ":lua require('iron.core').clear()<cr>","Repl clear")
--map("n", "<leader>rx", ":lua require('iron.core').exit()<cr>","Repl exit")
--map("n", "<leader>rn", ":lua require('iron.core').send_code_block_and_move()<cr>","Repl send block and move to next")
--map("n", "<leader>rl",":lua require('iron.core').send_line()<cr>","Repl send line")
--map("n", "<leader>rs",":lua require('iron.core').send_file()<cr>","Repl send file")
--map("v", "<leader>rv",":lua require('iron.core').mark_visual()<cr>","Repl mark visual")
--map("v", "<leader>rm",":lua require('iron.core').send_mark()<cr>","Repl send mark")
--map("n", "<leader>ru",":lua require('iron.core').send_until_cursor()<cr>","Repl send until cursor")

function ToggleReplLayout()
  local bufnr = _G.repl_bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    print("REPL buffer not found or not valid.")
    return
  end

  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    print("REPL window not found.")
    return
  end

  local screen_height = vim.o.lines
  local current_height = vim.api.nvim_win_get_height(winid)

  if current_height < screen_height - 2 then
    vim.api.nvim_win_set_height(winid, screen_height - 2)
  else
    vim.api.nvim_win_set_height(winid, math.floor(screen_height / 2))
  end
end

vim.keymap.set("n", "<leader>rt", ToggleReplLayout, { desc = "Toggle REPL layout" })

-- Enter normal mode when in terminal buffer
vim.api.nvim_set_keymap("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })


-- change list
map("n", "<leader>Cl", ":changes<CR>", "Change list")

-- quickfix list
map("n", "<leader>qfo", "<cmd>copen<CR>", "Quickfix open")
map("n", "<leader>qfc", "<cmd>cclose<CR>", "Quickfix close")
map("n", "<leader>qfd", "<cmd>cexpr []<CR>", "Quickfix delete")

-- Marks
map("n", "<leader>md", ":delm! | delm A-Z0-9<CR>", "Marks delete all")


-- Merge conflicts
vim.keymap.set("n", "<leader>1", ":diffget LOCAL<CR>", { desc = "Diffget LOCAL" })
vim.keymap.set("n", "<leader>2", ":diffget BASE<CR>", { desc = "Diffget BASE" })
vim.keymap.set("n", "<leader>3", ":diffget REMOTE<CR>", { desc = "Diffget REMOTE" })

-- Spring
local spring_run_mvn = "mvn spring-boot:run -Dspring-boot.run.properties=local"
local command = ':lua require("toggleterm").exec("' .. spring_run_mvn .. '")<CR>'
map("n", "<leader>jsr", command)
map("n", "<leader>jtc", ':lua require("java").test.run_current_class()<CR>', "Java test class")
map("n", "<leader>jtd", ':lua require("java").test.debug_current_class()<CR>', "Java Debug Test Class")
map("n", "<leader>jtm", ':lua require("java").test.run_current_method()<CR>', "Java Test Method")
map("n", "<leader>jtv", ":lua require('java').test.view_last_report()<CR>", "Java Test View")

-- trouble
wk.add({
	{ "<leader>x", group = "Trouble" },
})
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", "Toggle trouble")
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<CR>", "Trouble toggle quickfix")
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>", "Trouble toggle loclist")
map("n", "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>", "Trouble toggle references")

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

local home = vim.loop.os_homedir() -- Get the home directory dynamically
local notes_path = home .. "/cheatsheets/" -- Append the notes directory

vim.api.nvim_create_user_command("Notes", function()
	vim.cmd.edit(notes_path)
end, {})
