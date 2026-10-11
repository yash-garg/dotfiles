return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 1000,
        opts = {
            transparent_background = true,
            styles = {
                comments = {},
                conditionals = {},
            },
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)

            local function is_dark()
                local result = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null")
                return vim.trim(result) == "Dark"
            end

            local function apply_theme()
                if is_dark() then
                    vim.cmd("colorscheme catppuccin-mocha")
                else
                    vim.cmd("colorscheme catppuccin-latte")
                end
            end

            apply_theme()

            vim.keymap.set("n", "<leader>tt", apply_theme, { desc = "Sync theme with system" })

            vim.api.nvim_set_hl(0, "LspInlayHint", { bg = "", fg = "#615e75" })
        end,
    },

    -- Also available
    {
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = true,
        opts = {
            variant = "moon",
            styles = {
                bold = true,
                italic = false,
                transparency = true,
            },
        },
        config = function(_, opts)
            require("rose-pine").setup(opts)
        end,
    },
}
