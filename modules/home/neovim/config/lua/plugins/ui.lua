return {
    -- Dashboard
    {
        "echasnovski/mini.starter",
        version = "*",
        event = "VimEnter",
        opts = {},
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        config = function()
            local cp = require("catppuccin.palettes").get_palette()

            local bubbles_theme = {
                normal = {
                    a = { fg = cp.base, bg = cp.mauve },
                    b = { fg = cp.text, bg = cp.surface0 },
                    c = { fg = cp.text, bg = cp.surface1 },
                },
                command = { a = { fg = cp.base, bg = cp.green } },
                insert = { a = { fg = cp.base, bg = cp.blue } },
                visual = { a = { fg = cp.base, bg = cp.teal } },
                replace = { a = { fg = cp.base, bg = cp.red } },
                inactive = {
                    a = { fg = cp.text, bg = cp.base },
                    b = { fg = cp.text, bg = cp.base },
                    c = { fg = cp.text, bg = cp.surface1 },
                },
            }

            require("lualine").setup({
                options = {
                    theme = bubbles_theme,
                    component_separators = { left = "", right = "" },
                    globalstatus = true,
                    section_separators = { left = "", right = "" },
                },
                inactive_sections = {
                    lualine_a = { "filename" },
                    lualine_b = {},
                    lualine_c = {},
                    lualine_x = {},
                    lualine_y = {},
                    lualine_z = { "location" },
                },
                sections = {
                    lualine_a = { { "mode", padding = { left = 1, right = 2 } } },
                    lualine_b = { { "filename", padding = { left = 2, right = 1 } } },
                    lualine_c = { "branch" },
                    lualine_x = {
                        {
                            "diagnostics",
                            sources = { "nvim_diagnostic" },
                            sections = { "error", "warn" },
                            symbols = { error = "✗ ", warn = "⚠ " },
                            colored = true,
                        },
                    },
                    lualine_y = { "filetype" },
                    lualine_z = { "location" },
                },
                tabline = {},
                winbar = {},
            })
        end,
    },

    -- Notifications
    {
        "rcarriga/nvim-notify",
        opts = {
            background_colour = "#000000",
            fps = 60,
            render = "default",
            timeout = 1000,
            top_down = true,
            max_width = 400,
        },
    },

    -- File icons
    {
        "nvim-tree/nvim-web-devicons",
        config = function()
            require("nvim-web-devicons").setup({
                override = {
                    default_icon = { icon = "󰈚", name = "Default" },
                    c = { icon = "", name = "c" },
                    css = { icon = "", name = "css" },
                    dart = { icon = "", name = "dart" },
                    deb = { icon = "", name = "deb" },
                    Dockerfile = { icon = "", name = "Dockerfile" },
                    html = { icon = "", name = "html" },
                    jpeg = { icon = "󰉏", name = "jpeg" },
                    jpg = { icon = "󰉏", name = "jpg" },
                    js = { icon = "󰌞", name = "js" },
                    kt = { icon = "󱈙", name = "kt" },
                    lock = { icon = "󰌾", name = "lock" },
                    lua = { icon = "", name = "lua" },
                    mp3 = { icon = "󰎆", name = "mp3" },
                    mp4 = { icon = "", name = "mp4" },
                    out = { icon = "", name = "out" },
                    png = { icon = "󰉏", name = "png" },
                    py = { icon = "", name = "py" },
                    ["robots.txt"] = { icon = "󰚩", name = "robots" },
                    toml = { icon = "", name = "toml" },
                    ts = { icon = "󰛦", name = "ts" },
                    ttf = { icon = "", name = "TrueTypeFont" },
                    rb = { icon = "", name = "rb" },
                    rpm = { icon = "", name = "rpm" },
                    vue = { icon = "󰡄", name = "vue" },
                    woff = { icon = "", name = "WebOpenFontFormat" },
                    woff2 = { icon = "", name = "WebOpenFontFormat2" },
                    xz = { icon = "", name = "xz" },
                    zip = { icon = "", name = "zip" },
                },
                default = true,
            })
        end,
    },

}
