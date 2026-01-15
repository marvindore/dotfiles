return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons", opt = true },
		{ "dokwork/lualine-ex" },
	},
	event = "VeryLazy",
	config = function()
		local lualine = require("lualine")
		local icons = require("config.icons")

		local hide_in_width = function()
			return vim.fn.winwidth(0) > 80
		end

		local diagnostics = {
			"diagnostics",
			sources = { "nvim_diagnostic" },
			sections = { "error", "warn" },
			symbols = { error = " ", warn = " " },
			colored = true,
			update_in_insert = false,
			always_visible = true,
		}

		local diff = {
			"diff",
			colored = true,
			symbols = { added = " ", modified = "  ", removed = "  " }, -- changes diff symbols
			diff_color = { added = "diffAdd", modified = "diffChange", removed = "diffDelete" },
			cond = hide_in_width,
		}

		local mode = {
			"mode",
			fmt = function(str)
				return " " .. str .. " "
			end,
		}

		local filetype = {
			"filetype",
			icons_enabled = true,
			icon = nil,
		}

		local branch = {
			"branch",
			icons_enabled = true,
			icon = "",
		}

		local location = {
			"location",
			padding = 0,
		}

		local filename = {
			"filename",
			file_status = true,
			path = 1,
			symbols = {
				readonly = " ",
				unnamed = icons.kind.Unnamed,
				modified = " ",
			},
			-- fix lualine error in java https://github.com/nvim-lualine/lualine.nvim/issues/820
			fmt = function(str)
				--- @type string
				local fn = vim.fn.expand("%:~:.")
				if vim.startswith(fn, "jdt://") then
					return fn:gsub("?.*$", "")
				end
				return str
			end,
		}

		local fileformat = {
			"fileformat",
			symbols = {
				unix = "", -- e712
				dos = "", -- e70f
				mac = "", -- e711
			},
		}

		-- cool function for progress
		local progress = function()
			local current_line = vim.fn.line(".")
			local total_lines = vim.fn.line("$")
			local line_ratio = current_line / total_lines
			local index = math.ceil(line_ratio * 100)
			return index .. "%%"
		end

		local spaces = function()
			return "spaces: " .. vim.api.nvim_buf_get_option(0, "shiftwidth")
		end

		local function python_venv()
			local venv = os.getenv("VIRTUAL_ENV")
			if venv then
				return "🐍 " .. vim.fn.fnamemodify(venv, ":t") -- show just the env name
			else
				return ""
			end
		end

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "catppuccin", --"tokyonight",  --"catppuccin", -- "solarized_dark",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = { "dashboard", "NvimTree", "Outline" },
				always_divide_middle = true,
			},
			sections = {
				lualine_a = { mode },
				lualine_b = { filename, branch, diff, diagnostics },
				lualine_c = { python_venv, "lsp_progress" },
				-- lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_x = {
					function()
						return require("auto-session.lib").current_session_name(true)
					end,
					spaces,
					"encoding",
					fileformat,
					filetype,
					{
						"ex.lsp.all",

						fmt = function(str)
							return str ~= "" and ("running" .. str) or "off"
						end,

						-- If true then only clients attached to the current buffer will be shown:
						only_attached = false,

						-- If true then every closed client will be echoed:
						notify_enabled = true,

						-- The name of highlight group which should be used in echo:
						notify_hl = "Comment",
					},
				},
				lualine_y = { location, progress },
				lualine_z = {},
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { filename },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			extensions = {},
		})
	end,
}
