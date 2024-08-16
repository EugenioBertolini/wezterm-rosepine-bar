local wez = require "wezterm"

local config = {
  position = "bottom",
  max_width = 21, -- max width allowed on wsl I guess...
  left_separator = "  ", -- more beautiful
  right_separator = "  ", -- more beautiful
  field_separator = "  | ", -- more regular separation with one space removed
  leader_icon = "",
  workspace_icon = "",
  pane_icon = "",
  pane_icon_window = "",
  user_icon = "",
  hostname_icon = "󰒋",
  clock_icon = "󰃰",
  cwd_icon = "",
  enabled_modules = {
    username = true,
    hostname = true,
    clock = true,
    cwd = true,
  },
  ansi_colors = {
    workspace = 8,
    leader = 2,
    pane = 7,
    active_tab = 4,
    inactive_tab = 6,
    username = 6,
    hostname = 8,
    clock = 5,
    cwd = 7,
  },
}

local username = os.getenv "USER" or os.getenv "LOGNAME" or os.getenv "USERNAME"
local current_tab_path = ""

local M = {}

local function tableMerge(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k] or false) == "table" then
        tableMerge(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

local get_cwd_hostname = function(pane)
  local cwd, hostname = "", ""
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    cwd = cwd_uri.file_path
    hostname = cwd_uri.host or wez.hostname()
    -- Remove the domain name portion of the hostname
    local dot = hostname:find "[.]"
    if dot then
      hostname = hostname:sub(1, dot - 1)
    end
    if hostname == "" then
      hostname = wez.hostname()
    end
  end

  return cwd, hostname
end

local basename = function(path) -- get filename from path
  if type(path) ~= "string" then
    return nil
  end
  local file = ""
  if M.is_windows then
    file = path:gsub("(.*[/\\])(.*)", "%2") -- replace (path/ or path\)(file) with (file)
  else
    file = path:gsub("(.*/)(.*)", "%2") -- replace (path/)(file) with (file)
  end
  -- remove extension
  file = file:gsub("(%..+)$", "")
  return file
end

-- MODIFIED --> basename not applied here because it causes bugs when title is too long
local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

local get_leader = function(prev)
  local leader = config.leader_icon

  wez.log_info("prev: " .. prev)
  wez.log_info("prev size: " .. #prev)
  wez.log_info("leader: " .. leader)
  wez.log_info("leader size: " .. #leader)

  local spacing = #prev - #leader
  local first_half = math.floor(spacing / 2)
  local second_half = math.ceil(spacing / 2)
  wez.log_info("spacing: " .. spacing)
  wez.log_info("first_half: " .. first_half)
  wez.log_info("second_half: " .. second_half)
  return string.rep(" ", first_half) .. leader .. string.rep(" ", second_half)
end

-- conforming to https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd
-- exporting an apply_to_config function, even though we don't change the users config
-- MODIFIED --> scheme becomes c.colors(), to be compatible with both color schemes and tables
-- <in .wezterm.lua, write the content in one of the two if statement below, depending on your case>
-- if color_scheme
-- {
--    config.colors_scheme = "my-color-scheme-name"
--    config.colors = wezterm.color.get_builtin_schemes()[config.color_scheme]
-- }
-- if color_table
-- {
--    local theme = wezterm.plugin.require("some-color-scheme")
--    config.colors = theme.colors
-- }
-- MODIFIED --> switch order in tableMerge
M.apply_to_config = function(c, opts)
  -- make the opts arg optional
  if not opts then
    opts = {}
  end

  -- combine user config with defaults
  config = tableMerge(config, opts)

  local scheme = c.colors
  local default_colors = {
    tab_bar = {
      background = scheme.background,
      active_tab = {
        bg_color = scheme.background,
        fg_color = scheme.ansi[config.ansi_colors.active_tab],
      },
      inactive_tab = {
        bg_color = scheme.background,
        fg_color = scheme.ansi[config.ansi_colors.inactive_tab],
      },
    },
  }

  if c.colors == nil then
    c.colors = default_colors
  else
    c.colors = tableMerge(c.colors, default_colors)
  end

  c.use_fancy_tab_bar = false
  c.tab_bar_at_bottom = config.position == "bottom"
  c.tab_max_width = config.max_width
end

-- MODIFIED --> apply basename() here
-- MODIFIED --> check if basename(tab_title(tab)) returns empty string
-- MODIFIED --> should "truncate_left" and add "…" before filename
wez.on("format-tab-title", function(tab, _, _, conf, _, _)
  local palette = conf.resolved_palette

  local pre = (tab.tab_index + 1) .. config.left_separator
  local title = tab_title(tab)
  local post = "  "
  local offset = #pre + #post

  -- Windows: keep cwd name only (my WSL already returns cwd name only -> no need)
  if title:find "\\" then
    title = title:gsub("(.*[/\\])(.*)", "%2")
  end

  -- check if dir needs truncation
  local stripped_title = basename(title)
  if stripped_title == "" then
    title = "…" .. wez.truncate_left(title, conf.tab_max_width - offset - 1)
  elseif
    #stripped_title + offset > conf.tab_max_width
    and not (#stripped_title == #wez.truncate_left(stripped_title, conf.tab_max_width - offset))
  then
    title = "…" .. wez.truncate_left(stripped_title, conf.tab_max_width - offset - 1)
  else
    title = stripped_title
  end

  -- Windows: add my username (fuge) if title == "~" for parity with WSL
  if title == "~" and #title == 1 then
    title = username or title
  end

  -- WSL: It's cooler to show root as " /"
  if title == "…/" then
    title = " /"
  end

  -- Windows: to fix bug when in root directory (C:/ or D:/, ...)
  if title == "…" then
    title = tab_title(tab)
  end

  local fg = palette.tab_bar.inactive_tab.fg_color
  local bg = palette.tab_bar.inactive_tab.bg_color
  if tab.is_active then
    fg = palette.tab_bar.active_tab.fg_color
    bg = palette.tab_bar.active_tab.bg_color
    -- Windows: to fix bug with pane:get_current_working_dir() -> always returns $HOME
    current_tab_path = tab.active_pane.title
  end

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = pre .. title .. post },
  }
end)

-- Name of workspace
-- MODIFIED --> remove title from the pane icon box because it's ugly
-- and change color for clarity
wez.on("update-status", function(window, pane)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end

  local palette = conf.resolved_palette

  local cwd, hostname = get_cwd_hostname(pane)
  local pane_icon = config.pane_icon

  if string.find(cwd, "^/([A-Z]:)") then
    -- Windows: get cwd from exposed variable in format-tab-title
    cwd = current_tab_path
    cwd = cwd:gsub("\\", "/")
    pane_icon = config.pane_icon_window
  else
    -- WSL: cwd works but it doesn't replace $HOME with ~, so here we go
    cwd = cwd:gsub("/home/" .. username, "~")
  end

  -- left status
  local stat = " " .. config.workspace_icon .. " " .. window:active_workspace() .. " "
  local stat_fg = palette.ansi[config.ansi_colors.workspace]

  if window:leader_is_active() then
    stat_fg = palette.ansi[config.ansi_colors.leader]
    stat = get_leader(stat)
  end

  window:set_left_status(wez.format {
    { Background = { Color = palette.tab_bar.background } },
    { Foreground = { Color = stat_fg } },
    { Text = stat },

    { Foreground = { Color = palette.ansi[config.ansi_colors.active_tab] } },
    { Text = " " .. pane_icon .. "  " },
  })

  -- right status
  local cells = {
    { Background = { Color = palette.tab_bar.background } },
  }
  local enabled_modules = config.enabled_modules

  if enabled_modules.username then
    table.insert(cells, { Foreground = { Color = palette.ansi[config.ansi_colors.username] } })
    table.insert(cells, { Text = username })
    table.insert(cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(cells, { Text = config.right_separator .. config.user_icon .. config.field_separator })
  end

  if enabled_modules.hostname then
    table.insert(cells, { Foreground = { Color = palette.ansi[config.ansi_colors.hostname] } })
    table.insert(cells, { Text = hostname })
    table.insert(cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(cells, { Text = config.right_separator .. config.hostname_icon .. config.field_separator })
  end

  if enabled_modules.clock then
    table.insert(cells, { Foreground = { Color = palette.ansi[config.ansi_colors.clock] } })
    table.insert(cells, { Text = wez.time.now():format "%H:%M" })
    table.insert(cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(cells, { Text = config.right_separator .. config.clock_icon .. "  " })
  end

  if enabled_modules.cwd then
    table.insert(cells, { Foreground = { Color = palette.brights[1] } })
    table.insert(cells, { Text = config.cwd_icon .. " " })
    table.insert(cells, { Foreground = { Color = palette.ansi[config.ansi_colors.cwd] } })
    table.insert(cells, { Text = cwd .. " " })
  end

  window:set_right_status(wez.format(cells))
end)

return M
