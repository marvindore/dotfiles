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

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
config.window_decorations = "TITLE|RESIZE|MACOS_FORCE_DISABLE_SHADOW"

-- This is where you actually apply your config choices
config.default_cursor_style = "BlinkingBar"
config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Fira Code" })
config.warn_about_missing_glyphs = false
config.font_size = 13

-- config.default_domain = 'WSL:Ubuntu'
if os.getenv("OS") == "Windows_NT" then
	config.default_prog = { "pwsh.exe" }
  -- config.default_domain = 'WSL:Ubuntu'
end
config.color_scheme = "MaterialDarker"
-- tmux
-- if is_darwin() then
--   config.leader = { key = "a", mods = "CMD", timeout_milliseconds = 2000 }
-- else
--   config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
-- end

config.keys = {
	-- tmux defaults
	{ mods = "LEADER", key = "v", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER", key = "h", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER", key = "c", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ mods = "LEADER", key = "x", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ mods = "SHIFT", key = "LeftArrow", action = wezterm.action.ActivateTabRelative(-1) },
	{ mods = "SHIFT", key = "RightArrow", action = wezterm.action.ActivateTabRelative(1) },
	{ mods = "CTRL", key = "LeftArrow", action = wezterm.action.ActivatePaneDirection("Left") },
	{ mods = "CTRL", key = "DownArrow", action = wezterm.action.ActivatePaneDirection("Down") },
	{ mods = "CTRL", key = "UpArrow", action = wezterm.action.ActivatePaneDirection("Up") },
	{ mods = "CTRL", key = "RightArrow", action = wezterm.action.ActivatePaneDirection("Right") },
	{ mods = "LEADER", key = "LeftArrow", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
	{ mods = "LEADER", key = "RightArrow", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },
	{ mods = "LEADER", key = "DownArrow", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
	{ mods = "LEADER", key = "UpArrow", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
  { mods = "LEADER", key = "Space", action = wezterm.action.RotatePanes "Clockwise" },
  { mods = "LEADER", key = "0", action = wezterm.action.PaneSelect { mode = "SwapWithActive" }},

  -- session management
  { mods = "CTRL|SHIFT", key = "s", action = workspace_switcher.switch_workspace()},
  { mods = "CTRL|SHIFT", key = "t", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES"})},
  { mods = "CTRL|SHIFT", key = "[", action = act.SwitchWorkspaceRelative(1)},
  { mods = "CTRL|SHIFT", key = "]", action = act.SwitchWorkspaceRelative(-1)},

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
