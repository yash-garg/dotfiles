vim.g.mapleader = ","
vim.g.maplocalleader = ","

local map = vim.keymap.set

-- Normal mode
map("n", "<Space>", "<NOP>", { silent = true })
map("n", "<esc>", ":noh<CR>", { silent = true })
map("n", "Y", "y$", { silent = true })
map("n", "<leader>h", "^", { silent = true })
map("n", "<leader>l", "$", { silent = true })

-- Visual mode
map("v", "<TAB>", ">gv", { silent = true })
map("v", "<S-TAB>", "<gv", { silent = true })
