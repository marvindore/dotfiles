local install_list = {
	"bash",
	"cmake",
	"comment",
	"css",
	"cuda",
	"dockerfile",
	"gitignore",
	"graphql",
	"html",
	"http",
	"javascript",
	"jsdoc",
	"json",
	"json5",
	"latex",
	"lua",
	"make",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"regex",
	"scss",
	"sql",
	"svelte",
	"todotxt",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"vue",
	"yaml",
}

if vim.g.enableRust then
	table.insert(install_list, "rust")
end
if vim.g.enableJava then
	vim.list_extend(install_list, { "java", "kotlin" })
end
if vim.g.enableCsharp then
	table.insert(install_list, "c_sharp")
end
if vim.g.enableGo then
	vim.list_extend(install_list, { "go", "gomod", "gowork" })
end

-- 1. Load Textobjects (Must also be on the new API)
vim.pack.add({
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		name = "nvim-treesitter-textobjects",
	},
})

-- 2. Load the Main Plugin Eagerly
vim.pack.add({
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		name = "nvim-treesitter",
		data = {
			-- The new version requires manual updates when pulling changes
			run = function(_)
				vim.cmd("TSUpdate")
			end,
		},
	},
})

-- ==========================================
-- THE NEW CORE API CONFIGURATION
-- ==========================================

local ts = require("nvim-treesitter")

-- 1. Base Setup
ts.setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})

-- 2. Smart Installer
-- The new API dropped `ensure_installed`, so we manually
-- check what's missing and install only those.
local already_installed = ts.get_installed()
local to_install = vim.iter(install_list)
	:filter(function(parser)
		return not vim.tbl_contains(already_installed, parser)
	end)
	:totable()

if #to_install > 0 then
	ts.install(to_install)
end

-- 3. Core Neovim Integration
-- Highlighting, folding, and indentation are now triggered natively per buffer
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter_core_integration", { clear = true }),
	pattern = "*",
	callback = function(args)
		local bufnr = args.buf
		local ft = vim.bo[bufnr].filetype

		if not ft or ft == "" then
			return
		end

		-- Start Highlighting (Catches errors if parser isn't ready)
		pcall(vim.treesitter.start, bufnr)

		-- Enable Folding
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo.foldmethod = "expr"

		-- Enable Indentation
		vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

-- ==========================================
-- TEXT OBJECTS CONFIGURATION
-- ==========================================

-- 1. Setup lookahead
require("nvim-treesitter-textobjects").setup({
	select = { lookahead = true },
})

-- 2. Manual Keymaps
-- The new API requires mapping the Lua functions directly
local map = vim.keymap.set
local select_mod = require("nvim-treesitter-textobjects.select")
local move_mod = require("nvim-treesitter-textobjects.move")
local swap_mod = require("nvim-treesitter-textobjects.swap")

-- Selects
local selects = {
	["aa"] = "@parameter.outer",
	["ia"] = "@parameter.inner",
	["af"] = "@function.outer",
	["if"] = "@function.inner",
	["ac"] = "@class.outer",
	["ic"] = "@class.inner",
}
for key, query in pairs(selects) do
	map({ "x", "o" }, key, function()
		select_mod.select_textobject(query, "textobjects")
	end)
end

-- Moves (Next/Prev Start)
map({ "n", "x", "o" }, "]m", function()
	move_mod.goto_next_start("@function.outer", "textobjects")
end)
map({ "n", "x", "o" }, "]]", function()
	move_mod.goto_next_start("@class.outer", "textobjects")
end)
map({ "n", "x", "o" }, "[m", function()
	move_mod.goto_previous_start("@function.outer", "textobjects")
end)
map({ "n", "x", "o" }, "[[", function()
	move_mod.goto_previous_start("@class.outer", "textobjects")
end)

-- Moves (Next/Prev End)
map({ "n", "x", "o" }, "]M", function()
	move_mod.goto_next_end("@function.outer", "textobjects")
end)
map({ "n", "x", "o" }, "][", function()
	move_mod.goto_next_end("@class.outer", "textobjects")
end)
map({ "n", "x", "o" }, "[M", function()
	move_mod.goto_previous_end("@function.outer", "textobjects")
end)
map({ "n", "x", "o" }, "[]", function()
	move_mod.goto_previous_end("@class.outer", "textobjects")
end)

-- Swaps
map("n", "<leader>a", function()
	swap_mod.swap_next("@parameter.inner")
end)
map("n", "<leader>A", function()
	swap_mod.swap_previous("@parameter.inner")
end)
