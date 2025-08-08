local w = require("wezterm")
local utils = require("utils")

local font_name
if utils.is_windows() then
    font_name = "CaskaydiaMono Nerd Font Mono"
else
    font_name = "IosevkaTerm Nerd Font Mono"
end

local harfbuzz_features = { "ss02", "ss19", "ss20" }

local config = {
    adjust_window_size_when_changing_font_size = false,
    automatically_reload_config = true,
    bold_brightens_ansi_colors = true,
    check_for_updates = false,
    color_scheme = "Catppuccin Mocha",
    default_cursor_style = "SteadyBlock",
    disable_default_key_bindings = false,
    enable_scroll_bar = false,
    enable_tab_bar = false,
    font = w.font({
        family = font_name,
        weight = "Medium",
        harfbuzz_features = harfbuzz_features,
    }),
    font_rules = {
        {
            intensity = "Bold",
            italic = false,
            font = w.font({
                family = font_name,
                weight = "Bold",
                style = "Normal",
                harfbuzz_features = harfbuzz_features,
            }),
        },
        {
            intensity = "Normal",
            italic = true,
            font = w.font({
                family = font_name,
                weight = "Medium",
                style = "Italic",
                harfbuzz_features = harfbuzz_features,
            }),
        },
        {
            intensity = "Bold",
            italic = true,
            font = w.font({
                family = font_name,
                weight = "Bold",
                style = "Italic",
                harfbuzz_features = harfbuzz_features,
            }),
        },
    },
    font_size = 17,
    initial_cols = 130,
    initial_rows = 35,
    scrollback_lines = 5000,
    use_fancy_tab_bar = true,
    window_background_opacity = 1,
    window_close_confirmation = "NeverPrompt",
    window_padding = { left = 10, right = 10, top = 15, bottom = 15 },
    win32_system_backdrop = "Acrylic",
}

if utils.is_windows() then
    config.default_prog = { "pwsh" }
    config.font_size = 14
    config.window_background_opacity = 1
end

return config
