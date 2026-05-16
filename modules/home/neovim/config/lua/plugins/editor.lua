return {
    -- File explorer
    {
        "nvim-neo-tree/neo-tree.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        keys = {
            {
                "<leader>t",
                "<cmd>Neotree toggle right reveal_force_cwd focus<CR>",
                desc = "Explorer NeoTree (cwd)",
                silent = true,
            },
        },
        opts = {
            enable_diagnostics = true,
            enable_git_status = true,
            enable_modified_markers = true,
            enable_refresh_on_write = true,
            close_if_last_window = true,
            popup_border_style = "rounded",
            buffers = {
                bind_to_cwd = true,
                follow_current_file = { enabled = true },
            },
            window = {
                width = 30,
                height = 15,
                auto_expand_width = true,
                mappings = { ["<space>"] = "none" },
            },
        },
    },

    -- Git signs in gutter
    {
        "lewis6991/gitsigns.nvim",
        opts = { current_line_blame = true },
    },

    -- Auto pairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = { disable_filetype = { "TelescopePrompt" } },
    },

    -- Surround motions
    { "tpope/vim-surround" },

    -- Smooth scrolling
    {
        "karb94/neoscroll.nvim",
        opts = {},
    },

    -- Commenting
    {
        "numToStr/Comment.nvim",
        opts = {},
    },

    -- Todo highlights
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {},
    },

    -- Keybind hints
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {},
    },

    -- Bad habits enforcer
    {
        "m4xshen/hardtime.nvim",
        dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
        opts = {},
    },
}
