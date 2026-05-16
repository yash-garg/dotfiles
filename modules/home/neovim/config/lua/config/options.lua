local opt = vim.opt

opt.mouse = ""
opt.number = true
opt.relativenumber = true
opt.colorcolumn = ""
opt.wildmenu = true
opt.showmatch = true
opt.cursorline = true
opt.showcmd = true
opt.list = true
opt.listchars = {
    tab = "  ",
    trail = "·",
    extends = "→",
    precedes = "←",
    nbsp = "␣",
}
opt.inccommand = "nosplit"

-- Indentation
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.shiftround = true
opt.expandtab = true
opt.smarttab = true
opt.smartindent = true
opt.scrolloff = 4
opt.sidescrolloff = 4
opt.wrap = false

-- Search
opt.hlsearch = true
opt.ignorecase = true
opt.incsearch = true
opt.smartcase = true

-- Splits
opt.splitright = true
opt.splitbelow = true

opt.clipboard = "unnamedplus"

-- Menus
opt.pumheight = 16
opt.completeopt = { "menu", "menuone", "noselect" }

-- Folds
opt.foldmethod = "indent"
opt.foldnestmax = 3
opt.foldenable = false
