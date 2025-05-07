return {
	"Vigemus/iron.nvim",
	cmd = "IronRepl",
	config = function()
		local iron = require("iron.core")

		iron.setup({
			config = {
				scratch_repl = true, -- discard repls,
				repl_definition = {
					cs = {
						command = { "csharprepl" },
					},
					java = {
						command = { "jshell" },
					},
					go = {
						command = { "gore" },
					},
					lua = {
						command = { "lua" },
					},
					python = {
						command = { "ipython", "--no-autoindent" },
						-- command = { "python3" },
						format = function(lines, extras)
							--result = require("iron.fts.common").bracketed_paste_python(lines, extras) -- everything selected is one cell
							result = require("iron.fts.common").bracketed_paste_python(lines, extras)

							-- remove comments from output
							filtered = vim.tbl_filter(function(line)
								return not string.match(line, "^%s*#")
							end, result)
							return filtered
						end,
						block_deviders = { "# %%", "#%%" },
					},
					javascript = {
						command = { "node" },
					},
					typescript = {
						command = { "tsx" },
					},
					typescriptreact = {
						command = { "tsx" },
					},
					javascriptreact = {
						command = { "tsx" },
					},
				},
				repl_filetype = function(bufnr, ft)
					return ft
				end,
				repl_open_cmd = require("iron.view").split.vertical.botright("40%"),
			},
		  ignore_blank_lines = true, -- when sending visual select lines, IIAC to not submit extra prompt lines
		})
	end,
}
