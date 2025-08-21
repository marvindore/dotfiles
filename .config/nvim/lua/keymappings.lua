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

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "<leader><space>", "<C-^>", "Go to previous buffer")

-- Mini
map("n", "<leader>e", ":lua MiniFiles.open()<cr>")
map("n", "-", ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>", "Open parent directory")
map("n", "_", ":lua MiniFiles.close()<cr>", "Close parent directory")

-- Allow gf to open non-existent files
map("n", "gf", ":edit <cfile><CR>", "Open filename under cursor")

-- better window movement
map("n", "<C-h>", "<C-w>h", "Switch window left")
map("n", "<C-j>", "<C-w>j", "Switch window down")
map("n", "<C-k>", "<C-w>k", "Swith window up")
map("n", "<C-l>", "<C-w>l", "Switch window right")

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

-- Avante
if vim.g.enableAvante then
	map("n", "<leader>aa", "<cmd>AvanteToggle<CR>", "Avante Ask")
	map("n", "<leader>ab", "<cmd>AvanteBuild<cr>", "Avante Build")
	map("n", "<leader>ac", "<cmd>Avante Chat<cr>", "Avante Chat")
	map("n", "<leader>ar", "<cmd>AvanteRefresh<cr>", "Avante Refresh")
	map("n", "<leader>ae", "<cmd>AvanteEdit<cr>", "Avante Edit")
end

-- Copilot
if vim.g.enableCopilot then
	wk.add({
		{ "<leader>c", group = "Copilot" },
	})
	map("n", "<leader>cc", "<cmd>CopilotChatToggle<CR>", "Copilot Chat Toggle")
	map("v", "<leader>cf", "<cmd>CopilotChatFix<CR>", "Copilot Chat Fix")
	map("v", "<leader>co", "<cmd>CopilotChatOptimize<CR>", "Copilot Chat Optimize")
	map("v", "<leader>ce", "<cmd>CopilotCharExplain<CR>", "Copilot Chat Explain")
	map("v", "<leader>ct", "<cmd>CopilotChatTests<CR>", "Copilot Chat Tests")
	map("v", "<leader>cr", "<cmd>CopilotChatReview<CR>", "Copilot Chat Review")

	map("n", "<leader>ca", "<cmd>Copilot auth<CR>", "Copilot auth")
	map("n", "<leader>cs", "<cmd>Copilot suggestions<CR>", "Copilot suggestions")
end

-- Dbee
wk.add({
	{ "<LocalLeader>d", group = "Dbee" },
})
map("n", "<LocalLeader>do", "<cmd>lua require('dbee').open()<CR>", "Dbee Open")
map("n", "<LocalLeader>dc", "<cmd>lua require('dbee').close()<CR>", "Dbee Close")
map("n", "<LocalLeader>dd", "<cmd>lua require('dbee').toggle()<CR>", "Dbee Toggle")

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

-- Kulala
wk.add({
	{ "<leader>R", group = "Kulala" },
})
local lala = require("kulala")
map({ "n", "v" }, "<leader>Rs", function()
	lala.run()
end, "Send Message")
map({ "n", "v" }, "<leader>Ra", function()
	lala.run_all()
end, "Send Message")
map({ "n", "v" }, "<leader>Rr", function()
	lala.replay()
end, "Send Message")

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

-- Enter normal mode when in terminal buffer
vim.api.nvim_set_keymap("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

-- dap debugging
wk.add({
	{ "<leader>d", group = "Dap" },
})
map("n", "<leader>dn", ":lua require('osv').launch({port = 5677})<CR>", "Debug Neovim-kind") -- one step for vim kind debugger
map("n", "<F5>", ":lua require('dap').continue()<CR>", "Debug continue")
map("n", "<S-F5>", ":lua require'dap'.close()<cr>", "Debug stop")

map("n", "<F11>", ":lua require('dap').step_into()<CR>", "Debug step into")
map("n", "<F10>", ":lua require('dap').step_over()<CR>", "Debug step over")
map("n", "<S-F12>", ":lua require('dap').step_out()<CR>", "Debug step out")

map("n", "<leader>db", ":lua require'dap'.toggle_breakpoint()<CR>", "Debug toggle breakpoint")
map("n", "<leader>dr", ":lua require'dap'.restart()<cr>", "Debug restart")
map("n", "<leader>ds", ":lua require'dap'.stop()<cr>", "Debug stop")
map("n", "<leader>dT", ":lua require'dap'.terminate()<cr>", "Debug terminate")
map("n", "<leader>dC", ":lua require'dap'.clear_breakpoints()<CR>", "Debug clear breakpoints")
map("n", "<leader>dX", ":lua require'dap'.close()<CR>", "Debug close")
map("n", "<leader>dc", ":lua require'dap'.continue()<CR>", "Debug continue")
map("n", "<leader>dU", ":lua require'dap'.up()<CR>", "Debug up")
map("n", "<leader>dD", ":lua require'dap'.down()<CR>", "Debug down")
map(
	"n",
	"<leader>d_",
	":lua require'dap'.disconnect();require'dap'.stop();require'dap'.run_last()<CR>",
	"Debug stop run last"
)

map("n", "<leader>dR", ":lua require'dap'.repl.toggle({}, 'vsplit')<CR><C-w>l", "Debug toggle REPL")
map("n", "<Leader>dro", ":lua require('dap').repl.open()<CR>", "Debug open REPL")
map("n", "<Leader>drl", ":lua require('dap').repl.run_last()<CR>", "Debug run last REPL")

map("n", "<leader>de", ":lua require'dap'.set_exception_breakpoints({'all'})<CR>", "Debug execution breakpoint")
map(
	"n",
	"<Leader>dbc",
	":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
	"Debug condition breakpoint"
)
map(
	"n",
	"<Leader>dbm",
	":lua require('dap').set_breakpoint({ nil, nil, vim.fn.input('Log point message: ') })<CR>",
	"Debug breakpoint with message"
)

-- symbols
map("n", "<LocalLeader>aa", "<cmd>AerialToggle!<cr>", "Symbols outline")
map("n", "<LocalLeader>{", "<cmd>AerialPrev!<cr>", "Symbols outline")
map("n", "<LocalLeader>}", "<cmd>AerialNext!<cr>", "Symbols outline")
map("n", "<LocalLeader>af", "<cmd>call aerial#fzf()<cr>", "Symbols Fzf")

-- change list
map("n", "<leader>Cl", ":changes<CR>", "Change list")

-- quickfix list
map("n", "<leader>qfo", "<cmd>copen<CR>", "Quickfix open")
map("n", "<leader>qfc", "<cmd>cclose<CR>", "Quickfix close")
map("n", "<leader>qfd", "<cmd>cexpr []<CR>", "Quickfix delete")

-- Marks
map("n", "<leader>md", ":delm! | delm A-Z0-9<CR>", "Marks delete all")

-- fzf-lua
wk.add({
	{ "<LocalLeader>f", group = "Fuzzy Find" },
})
map("n", "<LocalLeader>ff", ":lua require('fzf-lua').files()<CR>", "Fzf Files")
map("n", "<LocalLeader>fr", ":lua require('fzf-lua').resume()<CR>", "Fzf Resume")
map("n", "<LocalLeader>fg", ":lua require('fzf-lua').grep_project()<CR>", "Fzf Grep")
map("n", "<LocalLeader>fG", ":lua require('fzf-lua').live_grep_glob()<CR>", "Fzf rg --glob")
map("n", "<LocalLeader>fl", ":lua require('fzf-lua').live_grep()<CR>", "Fzf Live Grep Current Project")
map("n", "<LocalLeader>fc", ":lua require('fzf-lua').lgrep_curbuf()<CR>", "Fzf Live Grep Current Buffer")
map("n", "<LocalLeader>fu", ":lua require('fzf-lua').grep_cword()<CR>", "Fzf Grep Word Under Cursor")

vim.keymap.set("n", "ml", function()
	require("fzf-lua").marks({
	  marks = "[A-Za-z]"
})
end, { desc = "Filtered Marks (a-z, A-Z)" })

-- diffview
diffview_toggle = function()
	local lib = require("diffview.lib")
	local view = lib.get_current_view()
	if view then
		-- Current tabpage is a Diffview; close it
		vim.cmd.DiffviewClose()
	else
		-- No open Diffview exists: open a new one
		vim.cmd.DiffviewOpen()
	end
end

map("n", "<leader>D", diffview_toggle, "DiffView Toggle")

-- git
local gitsigns = require("gitsigns")
map("n", "<leader>gg", ":lua require('neogit').open({ kind = 'floating'})<cr>", "Neogit Open")
map("n", "<leader>gs", ":lua require('gitsigns').show_commit()<cr>", "Show commit")
map("n", "<leader>]", ":lua require('gitsigns').next_hunk()<cr>", "Git Next Hunk")
map("n", "<leader>[", ":lua require('gitsigns').prev_hunk()<cr>", "Prev Next Hunk")
map("n", "<leader>gb", ":lua require('gitsigns').blame_line()<cr>", "Git Blame")
map("n", "<leader>gB", ":lua require('gitsigns').blame()<cr>", "Git Blame File")
map("n", "<leader>gp", ":lua require('gitsigns').preview_hunk_inline()<cr>", "Preview Hunk")
map("n", "<leader>ghs", ":lua require('gitsigns').stage_hunk<cr>", "Git Stage Hunk")
map("n", "<leader>ghr", ":lua require('gitsigns').reset_hunk<cr>", "Git Reset Hunk")
map("v", "<leader>ghs", function()
	gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end)
map("v", "<leader>ghr", function()
	gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end)

map("n", "<LocalLeader>gB", ":GitSigns blame<cr>", "Git Blame")

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

-- neotest
wk.add({
	{ "<leader>t", group = "Test" },
})
map("n", "<leader>tr", ':lua require("neotest").run.run()<CR>', "Test run under cursor")
map("n", "<leader>tf", ':lua require("neotest").run.run(vim.fn.expand("%"))<CR>', "Test run file")
map("n", "<leader>td", ':lua require("neotest").run.run({strategy = "dap"})<CR>', "Test debug")
map("n", "<leader>ts", ':lua require("neotest").run.stop()<CR>', "Test stop")
map("n", "<leader>ta", ':lua require("neotest").run.attach()<CR>', "Test attach")
map("n", "<leader>tt", ':lua require("neotest").summary.toggle()<CR>', "Test toggle summary")
map("n", "<leader>to", ':lua require("neotest").output.open()<CR>', "Test toggle summary output")
map("n", "<leader>tp", ':lua require("neotest").output_panel.toggle()<CR>', "Test toggle output panel")
map("n", "<leader>tw", ':lua require("neotest").watch.toggle()<CR>', "Test toggle watch")

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
local notes_path = home .. "/dotfiles/cheatsheets" -- Append the notes directory

vim.api.nvim_create_user_command("Notes", function()
	vim.cmd.edit(notes_path)
end, {})
