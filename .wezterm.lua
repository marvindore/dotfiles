-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local is_linux = function()
	return wezterm.target_triple:find("linux") ~= nil
end

local is_darwin = function()
	return wezterm.target_triple:find("darwin") ~= nil
end

-- windows path
local zoxide_path = ""

if is_darwin() then
  zoxide_path = "/opt/homebrew/bin/zoxide"
end

if is_linux() then
  zoxide_path = "/usr/bin/zoxide"
end

-- This table will hold the configuration.
local config = {}

config.max_fps = 120


-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- print workspace name at the upper right
wezterm.on("update-right-status", function(window, pane)
  window:set_right_status(window:active_workspace())
end)
-- load plugin
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
-- set path to zoxide
workspace_switcher.zoxide_path = zoxide_path

config.window_decorations = "TITLE|RESIZE|MACOS_FORCE_DISABLE_SHADOW"

-- This is where you actually apply your config choices
config.default_cursor_style = "BlinkingBar"
config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Fira Code" })
config.warn_about_missing_glyphs = false
config.font_size = 15

-- config.default_domain = 'WSL:Ubuntu'
if os.getenv("OS") == "Windows_NT" then
	config.default_prog = { "pwsh.exe" }
  -- config.default_domain = 'WSL:Ubuntu'
end
--config.default_prog = { "/opt/homebrew/bin/nu" }
config.color_scheme = "MaterialDarker"
-- tmux
-- if is_darwin() then
--   config.leader = { key = "a", mods = "CMD", timeout_milliseconds = 2000 }
-- else
--   config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
-- end

config.keys = {
	-- paste from clipboard
	{ key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	-- paste from primary selection
	{ key = "V", mods = "CTRL", action = act.PasteFrom("PrimarySelection") },
}

for i = 0, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = wezterm.action.ActivateTab(i),
	})
end

config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true
config.enable_wayland = false

-- tmux status
wezterm.on("update-right-status", function(window, _)
	local SOLID_LEFT_ARROW = ""
	local ARROW_FORGROUND = { Foreground = { Color = "#c6a0f6" } }
	local prefix = ""

	if window:leader_is_active() then
		prefix = " " .. utf8.char(0x1f30a) -- ocean wave
		SOLID_LEFT_ARROW = utf8.char(0xe0b2)
	end

	if window:active_tab():tab_id() ~= 0 then
		ARROW_FORGROUND = { Foreground = { Color = "#1e2030 " } }
	end

	window:set_left_status(wezterm.format({
		{ Background = { Color = "#b7bdf8" } },
		{ Text = prefix },
		ARROW_FORGROUND,
		{ Text = SOLID_LEFT_ARROW },
	}))
end)

-- and finally, return the configuration to wezterm
return config
