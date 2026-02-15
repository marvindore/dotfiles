vim.pack.add({
	{
		src = "https://github.com/Vigemus/iron.nvim",
		data = {
			-- Lazy load only when you explicitly launch the REPL
			cmd = { "IronRepl" },

			after = function(_)
				local iron = require("iron.core")
				local view = require("iron.view")

				iron.setup({
					keymaps = {
						clear = "<leader>rC",
						exit = "<leader>rx",
						interrupt = "<leader>rI",
						send_code_block = "<leader>rs",
						send_code_block_and_move = "<leader>rn",
						send_file = "<leader>rf",
						send_paragraph = "<leader>rp",
						send_line = "<leader>rl",
						send_until_cursor = "<leader>rc",
						visual_send = "<leader>rv",
						toggle_repl_with_cmd_1 = "<leader>rm",
						toggle_repl_with_cmd_2 = "<leader>rM",
					},
					config = {
						repl_open_cmd = {
							view.split.vertical.rightbelow("%35"),
							view.split.vertical.rightbelow("%100"),
						},
						scratch_repl = true, -- discard repls
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
								format = function(lines, extras)
									result = require("iron.fts.common").bracketed_paste_python(lines, extras)

									-- remove comments from output
									filtered = vim.tbl_filter(function(line)
										return not string.match(line, "^%s*#")
									end, result)
									return filtered
								end,
								block_dividers = { "# %%", "#%%" },
							},
							javascript = { command = { "deno" } },
							typescript = { command = { "deno" } },
							typescriptreact = { command = { "deno" } },
							javascriptreact = { command = { "deno" } },
						},
						repl_filetype = function(bufnr, ft)
							return ft
						end,
					},
					ignore_blank_lines = true,
				})
			end,
		},
	},
}, {
	-- Hand the data over to lze for lazy-loading
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
