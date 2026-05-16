return {
    -- Dashboard
    {
        "goolord/alpha-nvim",
        event = "VimEnter",
        config = function()
            require("alpha").setup(require("alpha.themes.startify").config)
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        config = function()
            local colors = {
                blue = "#80a0ff",
                cyan = "#89dceb",
                black = "#11111b",
                green = "#a6e3a1",
                white = "#cdd6f4",
                red = "#f38ba8",
                violet = "#cba6f7",
                grey = "#1e1e2e",
            }

            local bubbles_theme = {
                normal = {
                    a = { fg = colors.black, bg = colors.violet },
                    b = { fg = colors.white, bg = colors.grey },
                    c = { fg = colors.white },
                },
                command = { a = { fg = colors.black, bg = colors.green } },
                insert = { a = { fg = colors.black, bg = colors.blue } },
                visual = { a = { fg = colors.black, bg = colors.cyan } },
                replace = { a = { fg = colors.black, bg = colors.red } },
                inactive = {
                    a = { fg = colors.white, bg = colors.black },
                    b = { fg = colors.white, bg = colors.black },
                    c = { fg = colors.white },
                },
            }

            require("lualine").setup({
                options = {
                    theme = bubbles_theme,
                    component_separators = { left = "│", right = "│" },
                    globalstatus = true,
                    section_separators = { left = "", right = "" },
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
                    lualine_a = { { "mode", padding = { left = 1, right = 2 }, separator = { left = "" } } },
                    lualine_b = { { "filename", padding = { left = 2, right = 1 } }, "branch" },
                    lualine_c = { "%=" },
                    lualine_x = { "" },
                    lualine_y = { "filetype", "progress" },
                    lualine_z = { { "location", separator = { right = "" } } },
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

    -- Bufferline (disabled)
    {
        "akinsho/bufferline.nvim",
        enabled = false,
    },
}
