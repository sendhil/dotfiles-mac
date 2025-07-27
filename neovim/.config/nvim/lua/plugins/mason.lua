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
      
      -- Don't auto-install in the main Mason config
      -- Let mason-lspconfig and mason-tool-installer handle it
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "clangd",
          "rust_analyzer",
          "pyright",
          "ts_ls",
          "gopls",
          "lua_ls",
          "bufls",
          "yamlls",
          -- "nil_ls", -- Comment out for now, might not be available
        },
        automatic_installation = false, -- Don't auto-install
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
          "black",
          "ruff",
          "gofumpt",
          "goimports",
          "clang-tidy",
        },
        auto_update = false,
        run_on_start = false, -- Don't auto-install on startup
      })
    end,
  },
}