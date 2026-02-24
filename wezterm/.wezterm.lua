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
  }
end)

config.font_size = 20
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
