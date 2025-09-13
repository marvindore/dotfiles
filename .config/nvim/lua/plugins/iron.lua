return {
	"Vigemus/iron.nvim",
	cmd = "IronRepl",
	config = function()
		local iron = require("iron.core")
		local view = require("iron.view")

		iron.setup({
			keymaps = {
				clear = "<leader>rc",
				exit = "<leader>rx",
        interrupt = "<leader>rI",
				send_code_block = "<leader>rs",
				send_code_block_and_move = "<leader>rn",
				send_file = "<leader>rf",
				send_paragraph = "<leader>rp",
				send_line = "<leader>rl",
				send_until_cursor = "<leader>ru",
				visual_send = "<leader>rv",
				toggle_repl_with_cmd_1 = "<leader>rm",
				toggle_repl_with_cmd_2 = "<leader>rM"
			},
			config = {
			  repl_open_cmd = {
			    view.split.vertical.rightbelow("%35"),
			    view.split.vertical.rightbelow("%100")
			  },
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
						block_dividers = { "# %%", "#%%" },
					},
					javascript = {
						command = { "deno" },
					},
					typescript = {
						command = { "deno" },
					},
					typescriptreact = {
						command = { "deno" },
					},
					javascriptreact = {
						command = { "deno" },
					},
				},
				repl_filetype = function(bufnr, ft)
					return ft
				end,
			},
			ignore_blank_lines = true, -- when sending visual select lines, IIAC to not submit extra prompt lines
		})
	end,
}
