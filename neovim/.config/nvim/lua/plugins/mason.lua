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
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      -- Detect architecture
      local is_arm = vim.fn.system("uname -m"):match("arm") or vim.fn.system("uname -m"):match("aarch64")
      
      -- Build ensure_installed list based on architecture
      local ensure_installed = {
        "rust_analyzer",
        "pyright",
        "ts_ls", 
        "gopls",
        "lua_ls",
        "buf_ls", -- Use lspconfig name here
        "yamlls",
        -- "nil_ls", -- Comment out for now, might not be available
      }
      
      -- Only add clangd on non-ARM systems
      if not is_arm then
        table.insert(ensure_installed, 1, "clangd")
      end
      
      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
        automatic_installation = false, -- Don't auto-install
        -- This handles the mapping between lspconfig names and mason names
        handlers = {
          -- Default handler
          function(server_name)
            require("lspconfig")[server_name].setup({})
          end,
        },
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