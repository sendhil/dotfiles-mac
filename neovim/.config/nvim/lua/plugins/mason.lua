return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    event = "VeryLazy",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
    opts = {
      ensure_installed = {
        -- Language servers
        "clangd",
        "rust-analyzer",
        "pyright",
        "typescript-language-server",
        "gopls",
        "lua-language-server",
        "buf-language-server",
        "yaml-language-server",
        "nil_ls",
        
        -- Formatters
        "black",
        "gofumpt",
        "goimports",
        
        -- Linters
        "ruff",
        "clang-tidy",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", vim.schedule_wrap(function(pkg)
        vim.notify(string.format('Mason: %s was successfully installed', pkg.name))
      end))
      
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
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
          "nil_ls",
        },
        automatic_installation = true,
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
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
        run_on_start = true,
        start_delay = 3000, -- 3 seconds delay before auto-install
      })
    end,
  },
}