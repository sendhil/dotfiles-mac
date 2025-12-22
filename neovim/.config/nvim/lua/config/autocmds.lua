local augroup = vim.api.nvim_create_augroup("UserGoFormatting", { clear = true })

-- Ensure Go files are formatted on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  group = augroup,
  callback = function()
    local conform = require("conform")
    conform.format({ bufnr = 0, lsp_fallback = true })
  end,
  desc = "Format Go files on save",
})