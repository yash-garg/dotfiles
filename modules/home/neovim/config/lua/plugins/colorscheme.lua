return {
    -- Primary theme
    {
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = false,
        priority = 1000,
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
            vim.cmd("colorscheme rose-pine")
            vim.api.nvim_set_hl(0, "LspInlayHint", { bg = "", fg = "#615e75" })

            local dark = true
            vim.keymap.set("n", "<leader>tt", function()
                dark = not dark
                if dark then
                    vim.cmd("colorscheme rose-pine")
                else
                    vim.cmd("colorscheme rose-pine-dawn")
                end
            end, { desc = "Toggle light/dark theme" })
        end,
    },

    -- Also available (lazy loaded)
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        opts = {
            flavour = "mocha",
            transparent_background = true,
            styles = {
                comments = {},
                conditionals = {},
            },
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
        end,
    },
}
