local wezterm = require("wezterm")
local config = wezterm.config_builder()

local DARK = "tokyonight_storm"
local LIGHT = "tokyonight_day"

-- Add your favorite themes here
local FAVORITE_THEMES = {
	-- Tokyo Night
	"tokyonight_storm",
	"tokyonight_night",
	"tokyonight_day",
	-- Catppuccin
	"Catppuccin Mocha",
	"Catppuccin Macchiato",
	"Catppuccin Frappe",
	"Catppuccin Latte",
	-- Solarized
	"Solarized Dark (Gogh)",
	"Solarized Light (Gogh)",
	-- One
	"One Dark (Gogh)",
	"One Light (Gogh)",
	-- Nord
	"nord",
	-- Rosé Pine
	"Rosé Pine",
	"Rosé Pine Dawn",
	-- Kanagawa
	"Kanagawa (Gogh)",
	-- Everforest
	"Everforest Dark (Gogh)",
	"Everforest Light (Gogh)",
	-- Nightfox
	"nightfox",
	-- Ayu
	"ayu",
	"ayu_light",
	"ayu_mirage",
}

wezterm.on("augment-command-palette", function(window, pane)
	return {
		{
			brief = "Theme: Toggle light/dark",
			action = wezterm.action_callback(function(win, _)
				local overrides = win:get_config_overrides() or {}
				local current = overrides.color_scheme
				if current == LIGHT then
					overrides.color_scheme = DARK
				else
					overrides.color_scheme = LIGHT
				end
				win:set_config_overrides(overrides)
			end),
		},
		{
			brief = "Theme: Light",
			action = wezterm.action_callback(function(win, _)
				local overrides = win:get_config_overrides() or {}
				overrides.color_scheme = LIGHT
				win:set_config_overrides(overrides)
			end),
		},
		{
			brief = "Theme: Dark",
			action = wezterm.action_callback(function(win, _)
				local overrides = win:get_config_overrides() or {}
				overrides.color_scheme = DARK
				win:set_config_overrides(overrides)
			end),
		},
		{
			brief = "Theme: Clear override (back to config default)",
			action = wezterm.action_callback(function(win, _)
				win:set_config_overrides({})
			end),
		},
		{
			brief = "Theme: Pick from favorites",
			action = wezterm.action.InputSelector({
				title = "Select Theme",
				choices = (function()
					local choices = {}
					for _, theme in ipairs(FAVORITE_THEMES) do
						table.insert(choices, { id = theme, label = theme })
					end
					return choices
				end)(),
				action = wezterm.action_callback(function(win, pane, id, label)
					if id then
						local overrides = win:get_config_overrides() or {}
						overrides.color_scheme = id
						win:set_config_overrides(overrides)
					end
				end),
			}),
		},
		{
			brief = "Tab: Rename",
			action = wezterm.action.PromptInputLine({
				description = "Enter new name for tab",
				action = wezterm.action_callback(function(win, pane, line)
					if line then
						win:active_tab():set_title(line)
					end
				end),
			}),
		},
		{
			brief = "OpenCode: Pick session",
			action = wezterm.action.SendString("oc-session\n"),
		},
	}
end)

-- Includes Nerd Font v3 glyphs used by Pi's Powerline status bar.
config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
config.font_size = 23
config.line_height = 1.2
config.color_scheme = DARK

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

-- Preserve Cmd+Shift workspace navigation for Herdr without enabling the
-- Kitty keyboard protocol globally, which currently breaks plain Escape.
local function is_herdr_process(process)
	if process == "" then
		return false
	end

	local name = process:match("([^/\\]+)$") or process
	return name == "herdr" or name == "herdr.exe"
end

local function send_herdr_key(sequence, fallback_key, fallback_mods)
	return wezterm.action_callback(function(window, pane)
		local process = pane:get_foreground_process_name() or ""
		if is_herdr_process(process) then
			pane:send_text(sequence)
		else
			window:perform_action(
				wezterm.action.SendKey({ key = fallback_key, mods = fallback_mods }),
				pane
			)
		end
	end)
end

config.keys = {
	{
		key = "Escape",
		mods = "NONE",
		action = send_herdr_key("\x1b[27;1u", "Escape", "NONE"),
	},
	{
		key = "UpArrow",
		mods = "CMD|SHIFT",
		action = send_herdr_key("\x1b[1;10A", "UpArrow", "CMD|SHIFT"),
	},
	{
		key = "DownArrow",
		mods = "CMD|SHIFT",
		action = send_herdr_key("\x1b[1;10B", "DownArrow", "CMD|SHIFT"),
	},
	{
		key = "LeftArrow",
		mods = "CMD|SHIFT",
		action = send_herdr_key("\x1b[1;10D", "LeftArrow", "CMD|SHIFT"),
	},
	{
		key = "RightArrow",
		mods = "CMD|SHIFT",
		action = send_herdr_key("\x1b[1;10C", "RightArrow", "CMD|SHIFT"),
	},
	{
		key = "r",
		mods = "CMD|SHIFT",
		action = send_herdr_key("\x1b[114:82;10u", "r", "CMD|SHIFT"),
	},
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
