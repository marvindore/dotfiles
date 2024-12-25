return {
  'hoob3rt/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', opt = true },
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
      diff_color = { added = 'diffAdd', modified = 'diffChange', removed = 'diffDelete' },
      cond = hide_in_width
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
      end
    }

    local fileformat = {
      "fileformat",
      symbols = {
        unix = '', -- e712
        dos = '', -- e70f
        mac = '', -- e711
      }
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

    require('lualine').setup({
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
        lualine_c = {},
        -- lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_x = { spaces, "encoding", fileformat, filetype },
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
  end
}
