-- colors.lua (or paste into your init.lua)

-----------------------------------------------------------------------
-- 1) Install Kansō via vim.pack
-----------------------------------------------------------------------
vim.pack.add({
  { src = "https://github.com/webhooked/kanso.nvim.git" },
})

-----------------------------------------------------------------------
-- 2) Baseline UI options
-----------------------------------------------------------------------
vim.opt.termguicolors = true  -- full 24-bit color; recommended by most themes
vim.g.lualine_theme = "kanso"

-----------------------------------------------------------------------
-- 3) Kansō baseline configuration
--    Per README: setup must be called BEFORE `colorscheme kanso`.
-----------------------------------------------------------------------
local VARIANTS = { "zen", "ink", "mist", "pearl" }
local function is_light_variant(v) return v == "pearl" end

-- Choose your preferred startup pairing here
local DEFAULTS = {
  dark_variant  = "ink",
  light_variant = "pearl",
  minimal       = false,
  saturated     = false, -- false => "default", true => "saturated"
  compile       = false, -- keep false so runtime toggles are instant
}

-- Runtime state that we WILL update as you switch
local STATE = {
  minimal   = DEFAULTS.minimal,
  saturated = DEFAULTS.saturated,
  map       = { dark = DEFAULTS.dark_variant, light = DEFAULTS.light_variant },
}

-- Apply Kansō with current STATE
local function kanso_apply(extra_opts)
  local opts = vim.tbl_deep_extend("force", {
    background = { dark = STATE.map.dark, light = STATE.map.light },
    foreground = STATE.saturated and "saturated" or "default",
    minimal    = STATE.minimal,
    compile    = DEFAULTS.compile,
  }, extra_opts or {})

  require("kanso").setup(opts) -- setup first (README requirement)
  vim.cmd.colorscheme("kanso") -- then apply the colorscheme
end

-- Initial apply (dark by default)
vim.o.background = "dark"
kanso_apply()

-----------------------------------------------------------------------
-- 4) Toggles & variant switching
-----------------------------------------------------------------------

-- Toggle Minimal mode (reduced palette)
function _G.KansoToggleMinimal()
  STATE.minimal = not STATE.minimal
  kanso_apply()
  vim.notify("Kansō minimal: " .. (STATE.minimal and "ON" or "OFF"))
end

-- Toggle Saturated foreground (more vivid syntax colors)
function _G.KansoToggleSaturation()
  STATE.saturated = not STATE.saturated
  kanso_apply()
  vim.notify("Kansō foreground: " .. (STATE.saturated and "SATURATED" or "DEFAULT"))
end

-- Toggle background light/dark; mapping decides which variant is used
function _G.KansoToggleBackground()
  vim.o.background = (vim.o.background == "dark") and "light" or "dark"
  kanso_apply()
  vim.notify("Kansō background: " .. vim.o.background ..
             " (variant: " .. STATE.map[vim.o.background] .. ")")
end

-- Set a specific Kansō variant (zen | ink | mist | pearl)
function _G.KansoSetVariant(variant)
  local valid = {}
  for _, v in ipairs(VARIANTS) do valid[v] = true end
  if not valid[variant] then
    vim.notify("Kansō: invalid variant '" .. tostring(variant) .. "' (use zen|ink|mist|pearl)", vim.log.levels.ERROR)
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

  kanso_apply()
  vim.notify("Kansō variant: " .. variant .. " (background: " .. vim.o.background .. ")")
end

-- Cycle through variants, updating STATE.map and background appropriately
function _G.KansoCycleVariant()
  local current_variant = STATE.map[vim.o.background]           -- ← use live state (the bug fix)
  local idx = 1
  for i, v in ipairs(VARIANTS) do
    if v == current_variant then idx = i break end
  end

  local next_idx = (idx % #VARIANTS) + 1
  local next_variant = VARIANTS[next_idx]

  if is_light_variant(next_variant) then
    STATE.map.light = next_variant
    vim.o.background = "light"
  else
    STATE.map.dark = next_variant
    vim.o.background = "dark"
  end

  kanso_apply()
  vim.notify(
    ("Kansō cycled: %s (background: %s)"):format(next_variant, vim.o.background)
  )
end

-----------------------------------------------------------------------
-- 5) Keymaps (adjust <leader> bindings if you like)
-----------------------------------------------------------------------
vim.keymap.set("n", "<leader>um", _G.KansoToggleMinimal,    { desc = "Kansō: Toggle Minimal mode" })
vim.keymap.set("n", "<leader>us", _G.KansoToggleSaturation, { desc = "Kansō: Toggle Saturated foreground" })
vim.keymap.set("n", "<leader>ub", _G.KansoToggleBackground, { desc = "Kansō: Toggle Light/Dark background" })
vim.keymap.set("n", "<leader>uV", _G.KansoCycleVariant,     { desc = "Kansō: Cycle variant (zen/ink/mist/pearl)" })

-----------------------------------------------------------------------
-- 6) User commands (CLI-friendly)
-----------------------------------------------------------------------
vim.api.nvim_create_user_command("KansoMinimalToggle",    _G.KansoToggleMinimal,    {})
vim.api.nvim_create_user_command("KansoSaturationToggle", _G.KansoToggleSaturation, {})
vim.api.nvim_create_user_command("KansoBackgroundToggle", _G.KansoToggleBackground, {})
vim.api.nvim_create_user_command("KansoSetVariant", function(opts) _G.KansoSetVariant(opts.args) end, {
  nargs = 1, complete = function() return VARIANTS end
})
vim.api.nvim_create_user_command("KansoCycleVariant", _G.KansoCycleVariant, {})
