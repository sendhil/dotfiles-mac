return {
  {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end,
  },
{
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- LSP servers
          "lua-language-server",
          "pyright",
          "typescript-language-server",
          "gopls",
          "rust-analyzer",
          -- Formatters
          "black",
          "gofumpt",
          "goimports",
          -- Linters
          "ruff",
        },
        auto_update = false,
        run_on_start = false, -- Don't auto-install on startup
      })
    end,
  },
}