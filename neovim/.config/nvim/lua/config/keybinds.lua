vim.keymap.set("n", "<leader>ct", "<cmd>tabclose<CR>", { silent = true, noremap = true, desc = "Close current tab" })
vim.keymap.set("n", "<leader>st", "<cmd>tab split<CR>",
    { silent = true, noremap = true, desc = "Split window into new tab" })

-- Move up and down in command line completion
vim.keymap.set("c", "j", "<C-n>", { noremap = true, silent = true, desc = "Move down in command-line completion" })
vim.keymap.set("c", "k", "<C-p>", { noremap = true, silent = true, desc = "Move up in command-line completion" })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "man",
    callback = function()
        vim.keymap.set("n", "gd", "<cmd>Man<CR>",
            { buffer = true, noremap = true, silent = true, desc = "Open Man Page" })
    end,
})
