-- 1. Add lualine and its dependencies (lualine-ex completely removed)
vim.pack.add({
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
})

-- 2. Configuration Setup
local lualine = require("lualine")
local icons = require("config.icons")

local diagnostics = {
	"diagnostics",
	sources = { "nvim_diagnostic" },
	sections = { "error", "warn" },
	symbols = { error = " ", warn = " " },
	colored = true,
	update_in_insert = false,
	always_visible = true,
}

-- Native LSP Progress (Requires Neovim 0.10+)
local native_lsp_progress = {
	function()
		-- We MUST escape the '%' character into '%%' so Neovim
		-- doesn't try to evaluate it as a statusline command
		return vim.lsp.status():gsub("%%", "%%%%")
	end,
	cond = function()
		return vim.lsp.status() ~= ""
	end,
	color = { fg = "#a6adc8" },
}

-- Highly Efficient File Progress
local file_progress = {
	"progress",
	fmt = function(str)
		-- Built-in 'progress' can sometimes return single '%' signs.
		-- This safely escapes them to prevent E539 crashes.
		return str:gsub("%%", "%%%%")
	end,
}

local diff = {
	"diff",
	colored = true,
	symbols = { modified = "  " },
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
	fmt = function(str)
		local fn = vim.fn.expand("%:~:.")
		if vim.startswith(fn, "jdt://") then
			return fn:gsub("?.*$", "")
		end
		return str
	end,
}

local fileformat = {
	"fileformat",
	symbols = { unix = "", dos = "", mac = "" },
}

local spaces = function()
	local sw = vim.api.nvim_get_option_value("shiftwidth", { buf = 0 })
	return "spaces: " .. sw
end

local function python_venv()
	local venv = os.getenv("VIRTUAL_ENV")
	if venv then
		return "🐍 " .. vim.fn.fnamemodify(venv, ":t")
	else
		return ""
	end
end

-- Native Active LSP List (Buffer Local)
local active_lsp_clients = {
	function()
		local clients = vim.lsp.get_clients({ bufnr = 0 })
		if #clients == 0 then
			return "off"
		end

		local names = {}
		local seen = {}
		for _, client in ipairs(clients) do
			if not seen[client.name] then
				table.insert(names, client.name)
				seen[client.name] = true
			end
		end
		return "running: " .. table.concat(names, ", ")
	end,
	color = { fg = "#a6adc8" },
}

-- 3. Run Setup
lualine.setup({
	options = {
		icons_enabled = true,
		theme = "catppuccin",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = { "dashboard", "NvimTree", "Outline" },
		always_divide_middle = true,

		-- OFFICIAL FIX: Inject LSP triggers directly into Lualine's event loop
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
			events = {
				"WinEnter",
				"BufEnter",
				"BufWritePost",
				"SessionLoadPost",
				"FileChangedShellPost",
				"VimResized",
				"Filetype",
				"CursorMoved",
				"CursorMovedI",
				"ModeChanged",
				"LspAttach", -- Immediately updates UI when server connects
				"LspDetach", -- Immediately updates UI when server drops
			},
		},
	},
	sections = {
		lualine_a = { mode },
		lualine_b = { filename, branch, diff, diagnostics },
		lualine_c = { python_venv, native_lsp_progress },
		lualine_x = {
			function()
				if package.loaded["auto-session.lib"] then
					return require("auto-session.lib").current_session_name(true) or ""
				end
				return ""
			end,
			spaces,
			"encoding",
			fileformat,
			filetype,
			active_lsp_clients,
		},
		lualine_y = { location, file_progress },
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
})
