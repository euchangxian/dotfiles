-- Initialize Configuration
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local opacity = 1
local transparent_bg = "rgba(22, 24, 26, " .. opacity .. ")"

--- Get the current operating system
--- @return "windows"| "linux" | "macos"
local function get_os()
	local bin_format = package.cpath:match("%p[\\|/]?%p(%a+)")
	if bin_format == "dll" then
		return "windows"
	elseif bin_format == "so" then
		return "linux"
	end

	return "macos"
end

local host_os = get_os()

-- Font Configuration
config.font = wezterm.font({ family = "MesloLGS NF", weight = "Regular" })
config.font_size = 13.0

-- Color Configuration
config.colors = require("cyberdream")
config.force_reverse_video_cursor = true

-- Window Configuration
config.initial_rows = 120
config.initial_cols = 80
config.window_decorations = "RESIZE"
config.window_background_opacity = opacity
config.window_background_image = (os.getenv("WEZTERM_CONFIG_FILE") or ""):gsub("wezterm.lua", "bg-blurred.png")
config.window_close_confirmation = "AlwaysPrompt"
config.win32_system_backdrop = "Acrylic"

-- Performance Settings
config.max_fps = 120
config.animation_fps = 60
config.cursor_blink_rate = 250

-- Tab Bar Configuration
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = false
config.use_fancy_tab_bar = true
config.colors.tab_bar = {
	background = config.window_background_image and "rgba(0, 0, 0, 0)" or transparent_bg,
	new_tab = { fg_color = config.colors.background, bg_color = config.colors.brights[6] },
	new_tab_hover = { fg_color = config.colors.background, bg_color = config.colors.foreground },
}

-- Tab Formatting
wezterm.on("format-tab-title", function(tab, _, _, _, hover)
	local background = config.colors.brights[1]
	local foreground = config.colors.foreground

	if tab.is_active then
		background = config.colors.brights[7]
		foreground = config.colors.background
	elseif hover then
		background = config.colors.brights[8]
		foreground = config.colors.background
	end

	local title = tostring(tab.tab_index + 1)
	return {
		{ Foreground = { Color = background } },
		{ Text = "█" },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Foreground = { Color = background } },
		{ Text = "█" },
	}
end)

-- New Tab/Pane Configuration
wezterm.on("spawn", function(event)
	if event.window_id then
		-- inherit the cwd from the current pane
		return { cwd = event.pane:get_current_working_dir() }
	end
end)

-- Keybindings
config.keys = {}

for i = 1, 9 do
	-- Option + number to activate that window
	table.insert(config.keys, {
		key = tostring(i),
		mods = "SUPER",
		action = wezterm.action.ActivateWindow(i - 1),
	})

	-- CMD + number to activate that tab
	table.insert(config.keys, {
		key = tostring(i),
		mods = "OPT",
		action = wezterm.action.ActivateTab(i - 1),
	})
end

return config
