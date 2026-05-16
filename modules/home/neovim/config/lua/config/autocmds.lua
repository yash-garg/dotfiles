local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Show diagnostic float when cursor rests on warning/error
augroup("float_diagnostic_cursor", { clear = true })
autocmd({ "CursorHold", "CursorHoldI" }, {
    group = "float_diagnostic_cursor",
    callback = function()
        vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
    end,
})
