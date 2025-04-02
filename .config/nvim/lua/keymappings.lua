local utils = require("utils")

-- variables
local keymap = require("utils").keymap
local wk = require("which-key")

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

keymap("n", "<Space>", "<NOP>")

-- Format on all files not just LSP
map(
	"n",
	"<leader>F",
	":lua require('conform').format({ lsp_fallback = true, async = false, timeout_ms= 1000})<CR>",
	{ desc = "Format" }
)

-- * then cgn multi-cursor (TODO Remap not working)
-- local function customAsterisk()
--   vim.api.nvim_command([[keepjumps normal! mi*`i]])
--   print('asterisk remapped')
-- end
-- vim.api.nvim_set_keymap('n', '*', ':keepjumps normal! mi*`i<CR>' ,{noremap = true, silent = true, desc= "Use start without jumping to next word or adding to jump list"})

keymap("n", "<leader>W", ":WhichKey<cr>")

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- oil
keymap("n", "-", ':lua require("oil").open()<cr>', { desc = "Open parent directory" })
keymap("n", "_", ':lua require("oil").close()<cr>', { desc = "Close parent directory" })

-- Allow gf to open non-existent files
keymap("n", "gf", ":edit <cfile><CR>", { desc = "Open filename under cursor" })

-- better window movement
keymap("n", "<C-h>", "<C-w>h", { desc = "Switch window left" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Switch window down" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Swith window up" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Switch window right" })

-- Clear search
vim.api.nvim_create_user_command("C", 'let @/=""', {})

-- Commenting code
vim.keymap.set("n", "<C-_>", function()
	require("Comment.api").toggle.linewise.current()
end, { noremap = true, silent = true })
vim.keymap.set("v", "<C-\\>", function()
	require("Comment.api").toggle.blockwise.current()
end, { noremap = true, silent = true })

-- Copy and paste
keymap("v", "<C-c>", '"+yi', { silent = true })
keymap("v", "<C-x>", '"+c', { silent = true })
keymap("v", "<C-v>", 'c<ESC>"+p', { silent = true })
keymap("v", "<C-V>", '<ESC>"+pa', { silent = true })

-- Wrap selection
keymap("v", ",b", [[c{ <c-r>" }<esc>]], { silent = true }) -- surround curly braces
keymap("v", ",B", [[c[<c-r>"]<esc>]], { silent = true }) -- surround square brackets
keymap("v", ",t", [[c`<c-r>"`<esc>]], { silent = true }) -- surround back ticks
keymap("v", ",s", [[c <c-r>" <esc>]], { silent = true }) -- surround single space
keymap("v", ",q", [[c'<c-r>"'<esc>]], { silent = true }) -- surround single quotes
keymap("v", ",Q", [[c"<c-r>""<esc>]], { silent = true }) -- surround double quotes
keymap("v", ",p", [[c(<c-r>")<esc>]], { silent = true }) -- surround single parentheses

-- Avante
if utils.enableAvante then
  map("n", "<LocalLeader>aa", "<cmd>AvanteToggle<CR>", { desc = "Avante Ask" })
  map("n", "<LocalLeader>ab", "<cmd>AvanteBuild<cr>", { desc = "Avante Build" })
  map("n", "<LocalLeader>ac", "<cmd>Avante Chat<cr>", { desc = "Avante Chat" })
  map("n", "<LocalLeader>ar", "<cmd>AvanteRefresh<cr>", { desc = "Avante Refresh" })
  map("n", "<LocalLeader>ae", "<cmd>AvanteEdit<cr>", { desc = "Avante Edit" })
end

-- Codeium
if utils.enableCodeium then
 map("n", "<leader>ca", "<cmd>Codeium Auth<cr>", {desc = "Codeium Auth"})
 map("n", "<leader>cc", "<cmd>Codeium Chat<cr>", {desc = "Codeium Chat"})
end

-- Copilot
if utils.enableCopilot then
  wk.add({
    { "<leader>c", group = "Copilot" },
  })
  map("n", "<leader>cc", "<cmd>CopilotChatToggle<CR>", { desc = "Copilot Chat Toggle" })
  map("v", "<leader>cf", "<cmd>CopilotChatFix<CR>", { desc = "Copilot Chat Fix" })
  map("v", "<leader>co", "<cmd>CopilotChatOptimize<CR>", { desc = "Copilot Chat Optimize" })
  map("v", "<leader>ce", "<cmd>CopilotCharExplain<CR>", { desc = "Copilot Chat Explain" })
  map("v", "<leader>ct", "<cmd>CopilotChatTests<CR>", { desc = "Copilot Chat Tests" })
  map("v", "<leader>cr", "<cmd>CopilotChatReview<CR>", { desc = "Copilot Chat Review" })

  map("n", "<leader>ca", "<cmd>Copilot auth<CR>", { desc = "Copilot auth" })
  map("n", "<leader>cs", "<cmd>Copilot suggestions<CR>", { desc = "Copilot suggestions" })
end

-- Dbee
wk.add({
	{ "<LocalLeader>d", group = "Dbee" },
})
map("n", "<LocalLeader>do", "<cmd>lua require('dbee').open()<CR>", { desc = "Dbee Open" })
map("n", "<LocalLeader>dc", "<cmd>lua require('dbee').close()<CR>", { desc = "Dbee Close" })
map("n", "<LocalLeader>dd", "<cmd>lua require('dbee').toggle()<CR>", { desc = "Dbee Toggle" })


-- Better indenting
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Move while insert mode
keymap("i", "<C-l>", "<Right>")
keymap("i", "<C-h>", "<Left>")
keymap("i", "<C-j>", "<Down>")
keymap("i", "<C-k>", "<Up>")

-- Moving to start or end of line (insert mode)
-- <C-o> switches vim to insert mode for one command
keymap("i", t("<C-e>"), "<C-o>$")
keymap("i", t("<C-a>"), "<C-o>0")

-- Scroll
keymap("n", "<C-left>", "10zh")
keymap("n", "<C-right>", "10zl")

-- Move selected block in visual mode
keymap("x", "K", ":move '<-2<CR>gv-gv")
keymap("x", "J", ":move '>+1<CR>gv-gv")

-- resize with arrows terminal not recognizing as unique sequence, use mouse instead
-- keymap("n", "<C-S-U>", ":resize +2<cr>")
-- keymap("n", "<C-S-Down>", ":resize -2<cr>")
-- keymap("n", "<C-S-Left>", ":vertical resize -2<cr>")
-- keymap("n", "<C-S-Right>", ":vertical resize +2<cr>")

-- Curl
wk.add({
	{ "<LocalLeader>c", group = "Curl" },
})
local curl = require("curl")
curl.setup({})

vim.keymap.set("n", "<LocalLeader>cc", function()
    curl.open_curl_tab()
end, { desc = "Open a curl tab scoped to the current working directory" })

vim.keymap.set("n", "<LocalLeader>co", function()
    curl.open_global_tab()
end, { desc = "Open a curl tab with gloabl scope" })

-- These commands will prompt you for a name for your collection
vim.keymap.set("n", "<LocalLeader>csc", function()
      curl.create_scoped_collection()
end, { desc = "Create or open a collection with a name from user input" })

vim.keymap.set("n", "<LocalLeader>cgc", function()
      curl.create_global_collection()
end, { desc = "Create or open a global collection with a name from user input" })

vim.keymap.set("n", "<LocalLeader>fsc", function()
      curl.pick_scoped_collection()
end, { desc = "Choose a scoped collection and open it" })

vim.keymap.set("n", "<LocalLeader>fgc", function()
      curl.pick_global_collection()
end, { desc = "Choose a global collection and open it" })

-- toggleterm
keymap("n", "<LocalLeader>th", ":ToggleTerm size=20 direction=horizontal<CR>", { desc = "Terminal horizontal" })
keymap("n", "<LocalLeader>tV", ":ToggleTerm size=110 direction=vertical<CR>", { desc = "Terminal vertical" })

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
map("n", "<leader>rr", ":IronRepl<cr>", { desc= "Repl start"} )
map("n", "<leader>rs", ":IronRepl<cr>", { desc= "Repl restart"} )
map("n", "<leader>rf",":lua require('iron.core').send_file()<cr>", {desc = "Repl send file"})
map("v", "<leader>rv",":lua require('iron.core').mark_visual()<cr>", {desc = "Repl mark visual"})
map("v", "<leader>rm",":lua require('iron.core').send_mark()<cr>", {desc = "Repl send mark"})
map("n", "<leader>ru",":lua require('iron.core').send_until_cursor()<cr>", {desc = "Repl send until cursor"})

-- nv-nvim-tree
--keymap("n", "<leader>nR", ":NvimTreeRefresh<CR>", { desc = "Tree refresh" })
keymap("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Tree togle" })
--keymap("n", "<leader>nF", ":NvimTreeFindFile<CR>", { desc = "Tree find file" })

-- neogen
-- map("n", "<leader>nc", ":lua require('neogen').generate({type = 'class'})<CR>", { desc = "Neogen Generate Class" })
-- map("n", "<leader>nf", ":lua require('neogen').generate({type = 'func'})<CR>", { desc = "Neogen Generate Func" })
-- map("n", "<leader>nt", ":lua require('neogen').generate({type = 'type'})<CR>", { desc = "Neogen Generate Type" })

-- dap debugging
wk.add({
	{ "<leader>d", group = "Dap" },
})
map("n", "<leader>dn", ":lua require('osv').launch({port = 5677})<CR>", { desc = "Debug Neovim-kind" })
map("n", "<F5>", ":lua require('dap').continue()<CR>", { desc = "Debug continue" })
map("n", "<S-F5>", ":lua require'dap'.close()<cr>", { desc = "Debug stop" })

map("n", "<F11>", ":lua require('dap').step_into()<CR>", { desc = "Debug step into" })
map("n", "<F10>", ":lua require('dap').step_over()<CR>", { desc = "Debug step over" })
map("n", "<S-F12>", ":lua require('dap').step_out()<CR>", { desc = "Debug step out" })

map("n", "<leader>db", ":lua require'dap'.toggle_breakpoint()<CR>", { desc = "Debug toggle breakpoint" })
map("n", "<leader>dr", ":lua require'dap'.restart()<cr>", { desc = "Debug restart" })
map("n", "<leader>ds", ":lua require'dap'.stop()<cr>", { desc = "Debug stop" })
map("n", "<leader>dT", ":lua require'dap'.terminate()<cr>", { desc = "Debug terminate" })
map("n", "<leader>dC", ":lua require'dap'.clear_breakpoints()<CR>", { desc = "Debug clear breakpoints" })
map("n", "<leader>dX", ":lua require'dap'.close()<CR>", { desc = "Debug close" })
map("n", "<leader>dc", ":lua require'dap'.continue()<CR>", { desc = "Debug continue" })
map("n", "<leader>dU", ":lua require'dap'.up()<CR>", { desc = "Debug up" })
map("n", "<leader>dD", ":lua require'dap'.down()<CR>", { desc = "Debug down" })
map(
	"n",
	"<leader>d_",
	":lua require'dap'.disconnect();require'dap'.stop();require'dap'.run_last()<CR>",
	{ desc = "Debug stop run last" }
)

map("n", "<leader>dR", ":lua require'dap'.repl.toggle({}, 'vsplit')<CR><C-w>l", { desc = "Debug toggle REPL" })
map("n", "<Leader>dro", ":lua require('dap').repl.open()<CR>", { desc = "Debug open REPL" })
map("n", "<Leader>drl", ":lua require('dap').repl.run_last()<CR>", { desc = "Debug run last REPL" })

map(
	"n",
	"<leader>de",
	":lua require'dap'.set_exception_breakpoints({'all'})<CR>",
	{ desc = "Debug execution breakpoint" }
)
map(
	"n",
	"<Leader>dbc",
	":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
	{ desc = "Debug condition breakpoint" }
)
map(
	"n",
	"<Leader>dbm",
	":lua require('dap').set_breakpoint({ nil, nil, vim.fn.input('Log point message: ') })<CR>",
	{ desc = "Debug breakpoint with message" }
)
--map("n", "<leader>da", ":lua require'debugHelper'.attach()<CR>", { desc = "Debug attach" })
--map("n", "<leader>dA", ":lua require'debugHelper'.attachToRemote()<CR>", { desc = "Debug attach remote" })

-- dapview
vim.keymap.set("n", "<leader>dv", function()
    require("dap-view").toggle()
end, { desc = "Toggle nvim-dap-view" })
vim.keymap.set("n", "<leader>da", function()
    require("dap-view").add_expr()
end, { desc = "Dapview add expression" })
map("n", "<leader>dw", ":DapViewWatch<cr>", {desc = "Dapview Watch"})

-- symbols
keymap("n", "<LocalLeader>s", ":Outline<cr>", { desc = "Symbols outline" })

-- change list
map("n", "<leader>Cl", ":changes<CR>", { desc = "Change list" })

-- quickfix list
map("n", "<leader>qfo", "<cmd>copen<CR>", { desc = "Quickfix open" })
map("n", "<leader>qfc", "<cmd>cclose<CR>", { desc = "Quickfix close" })
map("n", "<leader>qfd", "<cmd>cexpr []<CR>", { desc = "Quickfix delete" })

-- harpoon
wk.add({
	{ "<leader>h", group = "Harpoon" },
})
local harpoon = require("harpoon")
map("n", "<leader>hl", ":Telescope harpoon marks<CR>", { desc = "Harpoon list marks" })
vim.keymap.set("n", "<leader>ha", function()
	harpoon:list():add()
end, { desc = "Harpoon add mark file" })

vim.keymap.set("n", "<leader>hh", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon toggle menu" })

vim.keymap.set("n", ";1", function()
	harpoon:list():select(1)
end, { desc = "Harpoon select file 1" })

vim.keymap.set("n", ";2", function()
	harpoon:list():select(2)
end, { desc = "Harpoon select file 2" })

vim.keymap.set("n", ";3", function()
	harpoon:list():select(3)
end, { desc = "Harpoon select file 3" })

vim.keymap.set("n", ";4", function()
	harpoon:list():select(4)
end, { desc = "Harpoon select file 4" })

vim.keymap.set("n", "<leader>hn", function()
	harpoon:list():next()
end, { desc = "Harpoon next" })

vim.keymap.set("n", "<leader>hp", function()
	harpoon:list():next()
end, { desc = "Harpoon previous" })

map("n", "<leader>ml", ":Telescope marks<CR>", { desc = "Marks telescope" })
map("n", "<leader>md", ":delm! | delm A-Z0-9<CR>", { desc = "Marks delete all"})

-- fzf-lua
wk.add({
	{ "<LocalLeader>f", group = "Fuzzy Find" },
})
map("n", "<LocalLeader>ff", ":lua require('fzf-lua').files()<CR>", { desc = "Fzf Files" })
map("n", "<LocalLeader>fr", ":lua require('fzf-lua').resume()<CR>", { desc = "Fzf Resume" })
map("n", "<LocalLeader>fg", ":lua require('fzf-lua').grep_project()<CR>", { desc = "Fzf Grep" })
map("n", "<LocalLeader>fG", ":lua require('fzf-lua').live_grep_glob()<CR>", { desc = "Fzf rg --glob" })
map("n", "<LocalLeader>fl", ":lua require('fzf-lua').live_grep()<CR>", { desc = "Fzf Live Grep Current Project" })
map("n", "<LocalLeader>fc", ":lua require('fzf-lua').lgrep_curbuf()<CR>", { desc = "Fzf Live Grep Current Buffer" })
map("n", "<LocalLeader>fu", ":lua require('fzf-lua').grep_cword()<CR>", { desc = "Fzf Grep Word Under Cursor" })


--
-- Telescope -- See `:help telescope.builtin`
--
-- navigate preview window with ctl-d ctl-u
wk.add({
	{ "<leader>f", group = "Telescope Find" },
})
-- Function to search files in the opened directory
local function search_files_in_opened_directory()
  local current_dir = vim.fn.expand('%:p:h') -- Get the current working directory
  current_dir = current_dir:gsub('^oil://', '')
  require('telescope.builtin').find_files({ cwd = current_dir })
end

map("n", "<S-h>", ":Telescope buffers sort_mru=true sort_lastused=true initial_mode=normal theme=ivy<cr>", {desc = "Telescope open buffers"})

vim.keymap.set("n", "<Leader>fi", ":lua require('telescope.builtin').find_files()<CR>", { desc = "[f]ind [f]iles" })
vim.keymap.set('n', '<leader>fo', function() search_files_in_opened_directory() end, { desc=  "[F]ind [O]pen directory"})
map(
	"n",
	"<Leader>ff",
	"<cmd>lua require('telescope.builtin').find_files({find_command= {'rg','--no-ignore','--hidden','--files','-g','!**/node_modules/*','-g','!**/.git/*'},})<cr>",
	{ desc = "Find ignored files" }
)
--vim.keymap.set("n", "<Leader>fF", ":lua require('telescope.builtin').find_files({})<CR>", { desc = '[f]ind [f]iles Exact Name' })
map(
	"n",
	"<Leader>fb",
	':lua require("telescope").extensions.file_browser.file_browser()<CR>',
	{ desc = "Telescope extensions file browse" }
)
map("n", "<Leader>fC", ":lua require('telescope.builtin').colorscheme()<CR>")
vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", "<cmd>e #<cr>", { desc = "Alternate Buffer" }) 
map("n", "<Leader>fc", ":Telescope commands<CR>", { desc = "Telescope commands" })
map("n", "<Leader>jl", ":Telescope jumplist<CR>", { desc = "Telescope jumplist" })
map("n", "<Leader>fq", ":Telescope quickfix<CR>", { desc = "Telescope quickfix" })
map("n", "<Leader>fh", ":Telescope quickfixhistory<CR>", { desc = "Telescope quick history" })
map("n", "<Leader>fg", ":Telescope live_grep<CR>", { desc = "Telescope live grep" })
map("n", "<Leader>fr", ":Telescope resume<CR>", { desc = "Telescope resume" })
map(
	"n",
	"<Leader>go",
	":lua require('telescope.builtin').live_grep({grep_open_files=true})<CR>",
	{ desc = "Telescope grep open files" }
)
map("n", "<Leader>fp", ":Telescope projects<CR>", { desc = "Telescope projects" })
map("n", "<Leader>tgs", ":Telescope git_status<CR>", { desc = "Telescope git status" })
map("n", "<Leader>tgf", ":Telescope git_files<CR>", { desc = "Telescope git files" })
map(
	"n",
	"<Leader>tgc",
	":lua require('telescope.builtin').git_commits({ git_command = {'git', 'log', '--pretty=reference'} })<cr>",
	{ desc = "Telescope git commits" }
)
map("n", "<Leader>tgt", ":Telescope git_stash<CR>", { desc = "Telescope git stash" })
map("n", "<Leader>tgb", ":Telescope git_branches<CR>", { desc = "Telescope git branches" })
vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })

-- telescope-dap
map("n", "<leader>dtf", ":Telescope dap frames<CR>", { desc = "Telescope dap frames" })
map("n", "<leader>dtc", ":Telescope dap commands<CR>", { desc = "Telescope dap commands" })
map("n", "<leader>dto", ":Telescope dap configurations<CR>", { desc = "Telescope dap configuration" })
map("n", "<leader>dlb", ":Telescope dap list_breakpoints<CR>", { desc = "Telescope dap breakpoints" })
map("n", "<leader>dtv", ":Telescope dap variables<CR>", { desc = "Telescope dap variables" })

-- git
--vim.api.nvim_set_keymap("n", "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", {noremap = true, silent = true})
--map("n", "<leader>lg", ":LazyGit<CR>", { desc = "Lazy git" })
local gitsigns = require('gitsigns')
map("n", "<leader>gs", ":lua require('neogit').open({ kind = 'vsplit'})<cr>", {desc = "Neogit Open"})
map("n", "<leader>gg", ":lua require('neogit').open({ kind = 'floating'})<cr>", {desc = "Neogit Open"})
map("n", "<leader>ghn", ":lua require('gitsigns').nav_hunk('next')<cr>", {desc = "Git Next Hunk"})
map("n", "<leader>ghp", ":lua require('gitsigns').nav_hunk('prev')<cr>", {desc = "Git Previous Hunk"})
map("n", "<leader>ghs", ":lua require('gitsigns').stage_hunk<cr>", {desc = "Git Stage Hunk"})
map("n", "<leader>ghr", ":lua require('gitsigns').reset_hunk<cr>", {desc = "Git Reset Hunk"})
map('v', '<leader>ghs', function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end)
map('v', '<leader>ghr', function()
      gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end)

map("n", "<LocalLeader>gb", ":BlameToggle<cr>", { desc = "Git Blame" })
-- Merge conflicts
vim.keymap.set("n", "<leader>1", ":diffget LOCAL<CR>", { desc = "Diffget LOCAL" })
vim.keymap.set("n", "<leader>2", ":diffget BASE<CR>", { desc = "Diffget BASE" })
vim.keymap.set("n", "<leader>3", ":diffget REMOTE<CR>", { desc = "Diffget REMOTE" })

local builtin = require("telescope.builtin")
local utils = require("telescope.utils")

vim.keymap.set("n", "<LocalLeader>fh", function()
	builtin.find_files({ cwd = utils.buffer_dir() })
end, { desc = "Find files in cwd" })
vim.keymap.set("n", "<LocalLeader>fu", function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer]" })

-- Spring
local spring_run_mvn = "mvn spring-boot:run -Dspring-boot.run.properties=local"
local command = ':lua require("toggleterm").exec("' .. spring_run_mvn .. '")<CR>'
map("n", "<leader>jsr", command)
map("n", "<leader>jtc", ':lua require("java").test.run_current_class()<CR>', { desc = "Java test class" })
map("n", "<leader>jtd", ':lua require("java").test.debug_current_class()<CR>', { desc = "Java Debug Test Class" })
map("n", "<leader>jtm", ':lua require("java").test.run_current_method()<CR>', { desc = "Java Test Method" })
map("n", "<leader>jtv", ":lua require('java').test.view_last_report()<CR>", { desc = "Java Test View" })

-- neotest
wk.add({
	{ "<leader>t", group = "Test" },
})
map("n", "<leader>tr", ':lua require("neotest").run.run()<CR>', { desc = "Test run under cursor" })
map("n", "<leader>tf", ':lua require("neotest").run.run(vim.fn.expand("%"))<CR>', { desc = "Test run file" })
map("n", "<leader>td", ':lua require("neotest").run.run({strategy = "dap"})<CR>', { desc = "Test debug" })
map("n", "<leader>ts", ':lua require("neotest").run.stop()<CR>', { desc = "Test stop" })
map("n", "<leader>ta", ':lua require("neotest").run.attach()<CR>', { desc = "Test attach" })
map("n", "<leader>tt", ':lua require("neotest").summary.toggle()<CR>', { desc = "Test toggle summary" })
map("n", "<leader>to", ':lua require("neotest").output.open()<CR>', { desc = "Test toggle summary output" })
map("n", "<leader>tp", ':lua require("neotest").output_panel.toggle()<CR>', { desc = "Test toggle output panel" })
map("n", "<leader>tw", ':lua require("neotest").watch.toggle()<CR>', { desc = "Test toggle watch" })

-- trouble
wk.add({
	{ "<leader>x", group = "Trouble" },
})
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Toggle trouble" })
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<CR>", { desc = "Trouble toggle quickfix" })
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>", { desc = "Trouble toggle loclist" })
map("n", "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>", { desc = "Trouble toggle references" })

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

local home = vim.loop.os_homedir()  -- Get the home directory dynamically
local notes_path = home .. "/dotfiles/cheatsheets"  -- Append the notes directory

vim.keymap.set("n", "<leader>N", ":e " .. notes_path .. "<CR>", { noremap = true, silent = true })
