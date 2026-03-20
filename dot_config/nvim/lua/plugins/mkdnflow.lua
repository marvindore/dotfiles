vim.pack.add({
	{
		src = "https://github.com/jakewvincent/mkdnflow.nvim",
		data = {
			ft = "markdown",

			after = function(_)
				require("mkdnflow").setup({
					on_attach = function(bufnr)
						local opts = { buffer = bufnr, silent = true }

						-- Smart Tab/S-Tab: use mkdnflow table nav when in a table, otherwise fall through to blink.cmp
						vim.keymap.set("i", "<Tab>", function()
							if require("mkdnflow").tables.isPartOfTable(vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[1]) then
								vim.cmd("MkdnTableNextCell")
							else
								vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
							end
						end, vim.tbl_extend("force", opts, { desc = "Mkdn: Table next cell / blink.cmp" }))

						vim.keymap.set("i", "<S-Tab>", function()
							if require("mkdnflow").tables.isPartOfTable(vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[1]) then
								vim.cmd("MkdnTablePrevCell")
							else
								vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
							end
						end, vim.tbl_extend("force", opts, { desc = "Mkdn: Table prev cell / blink.cmp" }))

						-- Register which-key groups and labels for mkdnflow
						local wk = require("which-key")
						wk.add({
							{ "<leader>m", group = "mkdnflow", buffer = bufnr },
							{ "<leader>my", group = "mkdnflow yank", buffer = bufnr },
							{ "<leader>i", group = "mkdnflow table insert", buffer = bufnr },
						})
					end,
					modules = {
						bib = false,
						buffers = true,
						conceal = true,
						cursor = true,
						folds = true,
						foldtext = true,
						links = true,
						lists = true,
						maps = true,
						paths = true,
						tables = true,
						templates = true,
						to_do = true,
						yaml = false,
						completion = false,
					},
					links = {
						style = "markdown",
						conceal = true,
						implicit_extension = "md",
						transform_on_create = function(text)
							text = text:gsub("[ /]", "-")
							text = text:lower()
							return text
						end,
					},
					new_file_template = {
						enabled = true,
						placeholders = {
							title = "link_title",
							date = "os_date",
						},
						template = "# {{ title }}\n\n## {{ date }}",
					},
					to_do = {
						highlight = true,
					},
					mappings = {
						-- Navigation: keep defaults
						MkdnEnter = { { "n", "v" }, "<CR>" },
						MkdnGoBack = { "n", "<BS>" },
						MkdnGoForward = { "n", "<Del>" },
						MkdnNextLink = { "n", "<Tab>" },
						MkdnPrevLink = { "n", "<S-Tab>" },
						MkdnFollowLink = false,
						MkdnNextHeading = { "n", "]]" },
						MkdnPrevHeading = { "n", "[[" },
						MkdnNextHeadingSame = { "n", "][" },
						MkdnPrevHeadingSame = { "n", "[]" },

						-- Links
						MkdnDestroyLink = { "n", "<M-CR>" },
						MkdnTagSpan = { "v", "<M-CR>" },
						MkdnYankAnchorLink = { "n", "<leader>mya" },  -- was yaa, conflicts with mini.ai "yank around argument"
						MkdnYankFileAnchorLink = { "n", "<leader>myf" }, -- was yfa, conflicts with vim yf{char}
						MkdnMoveSource = { "n", "<F2>" },
						MkdnCreateLink = false,
						MkdnCreateLinkFromClipboard = { { "n", "v" }, "<leader>p" },

						-- Headings
						MkdnIncreaseHeading = { { "n", "v" }, "+" },  -- shadows vim + (next line first non-blank), acceptable tradeoff
						MkdnDecreaseHeading = false, -- conflicts: `-` = mini.files open dir
						MkdnIncreaseHeadingOp = false, -- was g+, conflicts with vim undo tree (g+ = redo branch)
						MkdnDecreaseHeadingOp = false, -- was g-, conflicts with vim undo tree (g- = undo branch)

						-- To-do
						MkdnToggleToDo = { { "n", "v" }, "<C-Space>" },

						-- Lists: disable o/O override to keep default vim behavior
						MkdnNewListItem = false,
						MkdnNewListItemBelowInsert = false, -- would override `o`
						MkdnNewListItemAboveInsert = false, -- would override `O`
						MkdnExtendList = false,
						MkdnUpdateNumbering = { "n", "<leader>nn" },
						MkdnIndentListItem = { "i", "<C-t>" },
						MkdnDedentListItem = { "i", "<C-d>" },

						-- Tables: disable insert-mode Tab/S-Tab (conflicts with blink.cmp super-tab)
						MkdnTableNextCell = false,  -- was <Tab> (i), conflicts with blink.cmp
						MkdnTablePrevCell = false,  -- was <S-Tab> (i), conflicts with blink.cmp
						MkdnTableNextRow = false,
						MkdnTablePrevRow = { "i", "<M-CR>" },
						MkdnTableNewRowBelow = { "n", "<leader>ir" },
						MkdnTableNewRowAbove = { "n", "<leader>iR" },
						MkdnTableNewColAfter = { "n", "<leader>ic" },
						MkdnTableNewColBefore = { "n", "<leader>iC" },
						MkdnTableDeleteRow = false, -- conflicts: <leader>dr = DAP restart
						MkdnTableDeleteCol = false, -- conflicts: <leader>dc = diffview close

						-- Folds: disable both (conflicts: <leader>f = find files, <leader>F = format)
						MkdnFoldSection = false,
						MkdnUnfoldSection = false,

						-- Tab wrappers (disabled, handled by blink/native)
						MkdnTab = false,
						MkdnSTab = false,
					},
				})
			end,
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
