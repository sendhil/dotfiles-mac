local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font_size = 24
config.line_height = 1.2
config.color_scheme = "tokyonight_storm"

config.colors = {
	cursor_bg = "#7aa2f7",
	cursor_border = "#7aa2f7",
}

config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.max_fps = 120

config.exit_behavior = "Close"
config.clean_exit_codes = { 130 }
config.window_close_confirmation = "NeverPrompt"
config.skip_close_confirmation_for_processes_named = {
	"bash",
	"sh",
	"zsh",
	"fish",
	"tmux",
	"nu",
	"cmd.exe",
	"pwsh.exe",
	"powershell.exe",
	"zellij",
}

-- config.window_background_opacity = 0.92
-- config.macos_window_background_blur = 20

config.keys = {
	{
		key = "d",
		mods = "CMD",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "d",
		mods = "CMD|SHIFT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	-- Zoom in
	{
		key = "+",
		mods = "CMD",
		action = wezterm.action.IncreaseFontSize,
	},
	-- Zoom out
	{
		key = "-",
		mods = "CMD",
		action = wezterm.action.DecreaseFontSize,
	},
}

return config
