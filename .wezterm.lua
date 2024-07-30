local wezterm = require "wezterm"

-- Allow working with both the current release and the nightly
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- change colorscheme
config.colors = wezterm.plugin.require("https://github.com/neapsix/wezterm").moon.colors()
config.inactive_pane_hsb = { hue = 1.0, saturation = 1.0, brightness = 0.8 }
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- configure important settings
config.audible_bell = "Disabled"
config.scrollback_lines = 50000
config.enable_scroll_bar = false
config.default_domain = "WSL:Arch"

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_prog = { "pwsh.exe" }
end

-- change font
config.font = wezterm.font {
  family = "JetBrains Mono",
  weight = "Regular",
  harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
}
config.font_size = 11
config.line_height = 0.9

-- set leader key
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 10000 }

-- change keybinds
config.disable_default_key_bindings = true
config.keys = {
  -- send CTRL+Space to terminal anyway
  { key = "Space", mods = "LEADER|CTRL", action = wezterm.action { SendKey = { key = "Space", mods = "CTRL" } } },
  -- reload config
  { key = "r", mods = "LEADER", action = "ReloadConfiguration" },
  -- fullscreen and font size
  { key = "m", mods = "LEADER", action = "ToggleFullScreen" },
  { key = "Enter", mods = "ALT", action = "ToggleFullScreen" },
  { key = ";", mods = "ALT|CTRL", action = "IncreaseFontSize" },
  { key = "-", mods = "ALT|CTRL", action = "DecreaseFontSize" },
  { key = "0", mods = "LEADER", action = "ResetFontSize" },
  -- split, navigate, and resize panes
  { key = "^", mods = "LEADER", action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" } } },
  { key = "\\", mods = "LEADER", action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" } } },
  { key = "-", mods = "LEADER", action = wezterm.action { SplitVertical = { domain = "CurrentPaneDomain" } } },
  { key = "b", mods = "LEADER", action = wezterm.action { RotatePanes = "CounterClockwise" } },
  { key = "n", mods = "LEADER", action = wezterm.action { RotatePanes = "Clockwise" } },
  { key = "z", mods = "LEADER", action = "TogglePaneZoomState" },
  { key = "h", mods = "ALT|CTRL", action = wezterm.action { ActivatePaneDirection = "Left" } },
  { key = "j", mods = "ALT|CTRL", action = wezterm.action { ActivatePaneDirection = "Down" } },
  { key = "k", mods = "ALT|CTRL", action = wezterm.action { ActivatePaneDirection = "Up" } },
  { key = "l", mods = "ALT|CTRL", action = wezterm.action { ActivatePaneDirection = "Right" } },
  { key = "LeftArrow", mods = "ALT|CTRL", action = wezterm.action { AdjustPaneSize = { "Left", 4 } } },
  { key = "DownArrow", mods = "ALT|CTRL", action = wezterm.action { AdjustPaneSize = { "Down", 2 } } },
  { key = "UpArrow", mods = "ALT|CTRL", action = wezterm.action { AdjustPaneSize = { "Up", 2 } } },
  { key = "RightArrow", mods = "ALT|CTRL", action = wezterm.action { AdjustPaneSize = { "Right", 4 } } },
  -- spawn and navigate tabs
  { key = "c", mods = "LEADER", action = wezterm.action { SpawnTab = "CurrentPaneDomain" } },
  { key = "x", mods = "LEADER", action = wezterm.action { CloseCurrentPane = { confirm = false } } },
  { key = "w", mods = "LEADER", action = wezterm.action { CloseCurrentTab = { confirm = false } } },
  { key = "[", mods = "LEADER", action = wezterm.action { ActivateTabRelative = -1 } },
  { key = "]", mods = "LEADER", action = wezterm.action { ActivateTabRelative = 1 } },
  { key = "l", mods = "LEADER", action = "ShowLauncher" },
  { key = "s", mods = "LEADER", action = "ShowTabNavigator" },
  -- search, copy, and paste
  { key = "f", mods = "SHIFT|CTRL", action = wezterm.action { Search = { CaseSensitiveString = "" } } },
  { key = "v", mods = "SHIFT|CTRL", action = wezterm.action { PasteFrom = "Clipboard" } },
  { key = "Insert", mods = "SHIFT", action = wezterm.action { PasteFrom = "Clipboard" } },
  { key = "c", mods = "SHIFT|CTRL", action = wezterm.action { CopyTo = "Clipboard" } },
  -- other
  { key = "l", mods = "SHIFT|LEADER", action = wezterm.action.ShowDebugOverlay },
  { key = "UpArrow", mods = "SHIFT", action = wezterm.action { ScrollByLine = -1 } },
  { key = "UpArrow", mods = "SHIFT|CTRL", action = wezterm.action { ScrollByPage = -1 } },
  { key = "Home", mods = "SHIFT", action = "ScrollToTop" },
  { key = "DownArrow", mods = "SHIFT", action = wezterm.action { ScrollByLine = 1 } },
  { key = "DownArrow", mods = "SHIFT|CTRL", action = wezterm.action { ScrollByPage = 1 } },
  { key = "End", mods = "SHIFT", action = "ScrollToBottom" },
}

local bar = wezterm.plugin.require "https://github.com/EugenioBertolini/wezterm-rosepine-bar"
bar.apply_to_config(config, {
  position = "top",
  left_separator = "   ",
})

return config
