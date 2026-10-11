return {
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        opts = {
            provider_selector = function()
                return { "treesitter", "indent" }
            end,
        },
        config = function(_, opts)
            require("ufo").setup(opts)
            local function fix_fold_hl()
                vim.api.nvim_set_hl(0, "Folded", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "UfoFoldedBg", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "UfoFoldedEllipsis", { bg = "NONE" })
            end
            fix_fold_hl()
            vim.api.nvim_create_autocmd("ColorScheme", { callback = fix_fold_hl })
        end,
    },
}
