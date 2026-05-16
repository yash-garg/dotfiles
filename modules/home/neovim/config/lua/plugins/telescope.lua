return {
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-telescope/telescope-file-browser.nvim",
        },
        keys = {
            { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Grep (root dir)" },
            { "<leader><space>", "<cmd>Telescope buffers<cr>", desc = "+buffer" },
            { "<leader>p", "<cmd>Telescope git_files<cr>", desc = "Search git files" },
            { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Commits" },
            { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Status" },
            { "<C-f>", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
            { "<leader>wd", "<cmd>Telescope diagnostics<cr>", desc = "Workspace diagnostics" },
            { "<leader>fe", "<cmd>Telescope file_browser<cr>", desc = "File browser" },
        },
        opts = {
            defaults = {
                layout_config = {
                    horizontal = { prompt_position = "top" },
                },
                sorting_strategy = "ascending",
            },
        },
        config = function(_, opts)
            local telescope = require("telescope")
            telescope.setup(opts)
            telescope.load_extension("fzf")
            telescope.load_extension("file_browser")
        end,
    },
}
