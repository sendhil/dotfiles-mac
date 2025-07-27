return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
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
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        -- Add any additional tools here
      },
      auto_update = false,
      run_on_start = true,
    },
  },
}