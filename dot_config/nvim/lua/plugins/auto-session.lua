-- 1. Standard Vim session options (Removed 'globals' to prevent state corruption)
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions,globals"

-- 2. Add auto-session natively
vim.pack.add({
	"https://github.com/rmagatti/auto-session",
})

-- 3. Run the setup configuration immediately
require("auto-session").setup({
	suppressed_dirs = {
		"~/",
		"~/Projects",
		"~/Downloads",
		"/",
		"node_modules",
		"tmp",
		"*cache*",
		"~/.config",
		"~/.local",
	},

	-- CRITICAL FIX: Do not attempt to save or restore debugger and UI panels
	bypass_save_filetypes = {
		"terminal",
		"dap-repl",
		"dapui_watches",
		"dapui_breakpoints",
		"dapui_scopes",
		"dapui_console",
		"trouble",
	},
	bypass_session_save_file_types = {
		"terminal",
		"dap-repl",
		"dapui_watches",
		"dapui_breakpoints",
		"dapui_scopes",
		"dapui_console",
		"trouble",
	},
})
