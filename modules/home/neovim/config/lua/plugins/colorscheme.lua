return {
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
        end,
    },
}
