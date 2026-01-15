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

-- FIX: Use vim.list_extend instead of table.insert for lists
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

return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	event = { "BufReadPost", "BufNewFile" },
	-- 1. All configuration moved to opts
	opts = {
		ensure_installed = install_list,
		sync_install = false,
		auto_install = true,
		ignore_install = { "help", "vimdoc" }, -- Combined your duplicate keys
		modules = {},
		highlight = {
			enable = true,
			disable = { "c" },
		},
		indent = { enable = true },
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<c-space>",
				node_incremental = "<c-space>",
				scope_incremental = "<c-s>",
				node_decremental = "<c-backspace>",
			},
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					["aa"] = "@parameter.outer",
					["ia"] = "@parameter.inner",
					["af"] = "@function.outer",
					["if"] = "@function.inner",
					["ac"] = "@class.outer",
					["ic"] = "@class.inner",
				},
			},
			move = {
				enable = true,
				set_jumps = true,
				goto_next_start = {
					["]m"] = "@function.outer",
					["]]"] = "@class.outer",
				},
				goto_next_end = {
					["]M"] = "@function.outer",
					["]["] = "@class.outer",
				},
				goto_previous_start = {
					["[m"] = "@function.outer",
					["[["] = "@class.outer",
				},
				goto_previous_end = {
					["[M"] = "@function.outer",
					["[]"] = "@class.outer",
				},
			},
			swap = {
				enable = true,
				swap_next = {
					["<leader>a"] = "@parameter.inner",
				},
				swap_previous = {
					["<leader>A"] = "@parameter.inner",
				},
			},
		},
	},
	-- 2. Config now accepts opts and passes them to setup
	config = function(_, opts)
		require("nvim-treesitter.configs").setup(opts)
	end,
}
