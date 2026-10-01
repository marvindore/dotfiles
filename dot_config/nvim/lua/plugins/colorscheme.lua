-- colors.lua for kanagawa-paper

-----------------------------------------------------------------------
-- 1) Install Kanagawa Paper via vim.pack
-----------------------------------------------------------------------
vim.pack.add({
  { src = "https://github.com/thesimonho/kanagawa-paper.nvim.git" },
})

-- Manually add kanagawa-paper to runtimepath if not already present
local kanagawa_paper_path = vim.fn.stdpath("data") .. "/site/pack/core/opt/kanagawa-paper.nvim"
if vim.fn.isdirectory(kanagawa_paper_path) == 1 then
  local rtp = vim.o.runtimepath
  if not string.find(rtp, kanagawa_paper_path, 1, true) then
    vim.o.runtimepath = kanagawa_paper_path .. "," .. rtp
  end
end

-----------------------------------------------------------------------
-- 2) Baseline UI options
-----------------------------------------------------------------------
vim.opt.termguicolors = true

-----------------------------------------------------------------------
-- 2.5) kdiff3-style diff highlights
--    Kanagawa Paper's default diff colors are subtle; bump saturation.
--    Re-applied on every `:colorscheme kanagawa-paper*` (toggles included).
-----------------------------------------------------------------------
local function apply_diff_highlights()
  local dark = vim.o.background == "dark"
  if dark then
    vim.api.nvim_set_hl(0, "DiffAdd",    { bg = "#2c3b32" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#332323", fg = "#5c4646" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#28323b" })
    vim.api.nvim_set_hl(0, "DiffText",   { bg = "#3d342a", fg = "#e0af68", bold = true })
  else
    vim.api.nvim_set_hl(0, "DiffAdd",    { bg = "#dcefdc" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#f3dede", fg = "#b08c8c" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#dde7f3" })
    vim.api.nvim_set_hl(0, "DiffText",   { bg = "#f5f0e8", fg = "#77713F", bold = true })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "kanagawa-paper*",
  callback = apply_diff_highlights,
})

-----------------------------------------------------------------------
-- 3) Kanagawa Paper baseline configuration
--    Per docs: setup must be called BEFORE `colorscheme kanagawa-paper`.
--    Variants: ink (dark), canvas (light), auto (follows vim.o.background).
-----------------------------------------------------------------------
local VARIANTS = { "ink", "canvas" }
local function is_light_variant(v) return v == "canvas" end

-- Choose your preferred startup pairing here
local DEFAULTS = {
  dark_variant  = "ink",
  light_variant = "canvas",
  dim_inactive  = false,
  transparency  = false,
  gutter        = false,
}

-- Runtime state that we WILL update as you switch
local STATE = {
  dim_inactive = DEFAULTS.dim_inactive,
  transparency = DEFAULTS.transparency,
  gutter       = DEFAULTS.gutter,
  map          = { dark = DEFAULTS.dark_variant, light = DEFAULTS.light_variant },
}

-- Apply Kanagawa Paper with current STATE
local function kanagawa_paper_apply(extra_opts)
  local opts = vim.tbl_deep_extend("force", {
    undercurl = true,
    transparent = STATE.transparency,
    gutter = STATE.gutter,
    diag_background = true,
    dim_inactive = STATE.dim_inactive,
    terminal_colors = true,
    cache = false,

    styles = {
      comment = { italic = true },
      functions = { italic = false },
      keyword = { italic = false, bold = false },
      statement = { italic = false, bold = false },
      type = { italic = false },
    },

    color_balance = {
      ink = { brightness = 0, saturation = 0 },
      canvas = { brightness = 0, saturation = 0 },
    },

    overrides = function(colors)
      local theme = colors.theme
      return {
        -- Transparent floats
        NormalFloat = { bg = "none" },
        FloatBorder = { bg = "none" },
        FloatTitle = { bg = "none" },
      }
    end,

    auto_plugins = true,
    all_plugins = package.loaded.lazy == nil,
  }, extra_opts or {})

  require("kanagawa-paper").setup(opts)
  vim.cmd.colorscheme("kanagawa-paper")
end

-- Initial apply (dark by default)
vim.o.background = "dark"
kanagawa_paper_apply()

-- Configure lualine dynamically based on background
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "kanagawa-paper*",
  callback = function()
    local ok, lualine = pcall(require, "lualine")
    if ok then
      local theme_name = vim.o.background == "light" and "kanagawa-paper-canvas" or "kanagawa-paper-ink"
      local ok2, theme = pcall(require, "lualine.themes." .. theme_name)
      if ok2 then
        lualine.setup({ options = { theme = theme } })
      end
    end
  end,
})

-----------------------------------------------------------------------
-- 4) Toggles & variant switching
-----------------------------------------------------------------------

-- Toggle dimming of inactive windows
function _G.KanagawaPaperToggleDim()
  STATE.dim_inactive = not STATE.dim_inactive
  kanagawa_paper_apply()
  vim.notify("Kanagawa Paper dim inactive: " .. (STATE.dim_inactive and "ON" or "OFF"))
end

-- Toggle background transparency
function _G.KanagawaPaperToggleTransparency()
  STATE.transparency = not STATE.transparency
  kanagawa_paper_apply()
  vim.notify("Kanagawa Paper transparency: " .. (STATE.transparency and "ON" or "OFF"))
end

-- Toggle gutter background
function _G.KanagawaPaperToggleGutter()
  STATE.gutter = not STATE.gutter
  kanagawa_paper_apply()
  vim.notify("Kanagawa Paper gutter: " .. (STATE.gutter and "ON" or "OFF"))
end

-- Toggle background light/dark; mapping decides which variant is used
function _G.KanagawaPaperToggleBackground()
  vim.o.background = (vim.o.background == "dark") and "light" or "dark"
  kanagawa_paper_apply()
  vim.notify("Kanagawa Paper background: " .. vim.o.background ..
             " (variant: " .. STATE.map[vim.o.background] .. ")")
end

-- Set a specific Kanagawa Paper variant (ink | canvas)
function _G.KanagawaPaperSetVariant(variant)
  local valid = {}
  for _, v in ipairs(VARIANTS) do valid[v] = true end
  if not valid[variant] then
    vim.notify("Kanagawa Paper: invalid variant '" .. tostring(variant) .. "' (use ink|canvas)", vim.log.levels.ERROR)
    return
  end

  if is_light_variant(variant) then
    -- Light variant: bind to 'light' and switch background to light
    STATE.map.light = variant
    vim.o.background = "light"
  else
    -- Dark variant: bind to 'dark' and switch background to dark
    STATE.map.dark = variant
    vim.o.background = "dark"
  end

  kanagawa_paper_apply()
  vim.notify("Kanagawa Paper variant: " .. variant .. " (background: " .. vim.o.background .. ")")
end

-- Cycle through variants (dir = 1 forward, -1 backward), updating STATE.map
-- and background appropriately
function _G.KanagawaPaperCycleVariant(dir)
  dir = dir or 1
  local current_variant = STATE.map[vim.o.background]           -- use live state
  local idx = 1
  for i, v in ipairs(VARIANTS) do
    if v == current_variant then idx = i break end
  end

  local next_idx = ((idx - 1 + dir) % #VARIANTS) + 1
  local next_variant = VARIANTS[next_idx]

  if is_light_variant(next_variant) then
    STATE.map.light = next_variant
    vim.o.background = "light"
  else
    STATE.map.dark = next_variant
    vim.o.background = "dark"
  end

  kanagawa_paper_apply()
  vim.notify(
    ("Kanagawa Paper cycled: %s (background: %s)"):format(next_variant, vim.o.background)
  )
end

-----------------------------------------------------------------------
-- 5) Keymaps (adjust <leader> bindings if you like)
-----------------------------------------------------------------------
vim.keymap.set("n", "<leader>um", _G.KanagawaPaperToggleDim,          { desc = "Kanagawa Paper: Toggle dim inactive windows" })
vim.keymap.set("n", "<leader>us", _G.KanagawaPaperToggleTransparency, { desc = "Kanagawa Paper: Toggle transparency" })
vim.keymap.set("n", "<leader>ug", _G.KanagawaPaperToggleGutter,       { desc = "Kanagawa Paper: Toggle gutter" })
vim.keymap.set("n", "<leader>ub", _G.KanagawaPaperToggleBackground,   { desc = "Kanagawa Paper: Toggle Light/Dark background" })
vim.keymap.set("n", "<leader>uv", function() _G.KanagawaPaperCycleVariant(1) end,  { desc = "Kanagawa Paper: Cycle variant (ink/canvas)" })
vim.keymap.set("n", "]v", function() _G.KanagawaPaperCycleVariant(1) end,  { desc = "Kanagawa Paper: Next variant" })
vim.keymap.set("n", "[v", function() _G.KanagawaPaperCycleVariant(-1) end, { desc = "Kanagawa Paper: Previous variant" })

-----------------------------------------------------------------------
-- 6) User commands (CLI-friendly)
-----------------------------------------------------------------------
vim.api.nvim_create_user_command("KanagawaPaperDimToggle",          _G.KanagawaPaperToggleDim,          {})
vim.api.nvim_create_user_command("KanagawaPaperTransparencyToggle", _G.KanagawaPaperToggleTransparency, {})
vim.api.nvim_create_user_command("KanagawaPaperGutterToggle",       _G.KanagawaPaperToggleGutter,       {})
vim.api.nvim_create_user_command("KanagawaPaperBackgroundToggle",   _G.KanagawaPaperToggleBackground,   {})
vim.api.nvim_create_user_command("KanagawaPaperSetVariant", function(opts) _G.KanagawaPaperSetVariant(opts.args) end, {
  nargs = 1, complete = function() return VARIANTS end
})
vim.api.nvim_create_user_command("KanagawaPaperCycleVariant", function(opts)
  _G.KanagawaPaperCycleVariant(opts.args == "-1" and -1 or 1)
end, { nargs = "?" })
