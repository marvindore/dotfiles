return {
	"BurntSushi/ripgrep",
{
  "swaits/zellij-nav.nvim",
  lazy = true,
  event = "VeryLazy",
  opts = {},
},
	-- Editor
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
		config = function()
			local colors2 = require("catppuccin.palettes").get_palette()
			local U = require("catppuccin.utils.colors")
			local opts = {

				flavour = "mocha",
				term_colors = true,
				dim_inactive = {
					enabled = true,
					shade = "dark",
					percentage = 0.15,
				},
				styles = {
					comments = { "italic" },
				},
				integrations = {
					blink_cmp = true,
					gitsigns = true,
					nvimtree = true,
					fidget = true,
					flash = true,
					fzf = true,
					treesitter = true,
					treesitter_context = true,
					dap = { enabled = false, enabled_ui = false },
					lsp_trouble = true,
					overseer = true,
					mason = true,
					neogit = true,
					which_key = true,
					native_lsp = {
						enabled = true,
						virtual_text = {
							errors = {},
							hints = {},
							warnings = {},
							information = {},
						},
						underlines = {
							errors = { "underline" },
							hints = {},
							warnings = { "undercurl" },
							information = {},
						},
					},
				},
				custom_highlights = function(colors)
					return {
						DiffAdd = { bg = "#236724" },
						DiffChange = { fg = "#d3d3d3" },

						-- Changed text inside of a line (DiffChange)
						DiffText = { fg = "#000000", bg = "#C27601", style = { "bold" } },

						-- DiffDelete uses a conceal character that spans the entire line. Highlight
						-- that character instead of the background behind it.
						DiffDelete = { bg = "#9A0202" },
						LspReferenceRead = { bg = "#5f5840" },
						LspReferenceText = { bg = "#504945" },
						LspReferenceWrite = { bg = "#6c473e" },

						LightBulbVirtualText = { fg = colors.yellow },
						SpellBad = { style = { "underline" }, fg = colors.yellow },
					}
				end,
			}

			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
