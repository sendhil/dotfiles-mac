return {
  {
    {
      "jabirali/vim-tmux-yank",
      event = { "VeryLazy" }
    },
    {
      "ibhagwan/fzf-lua",
      -- optional for icon support
      dependencies = { "nvim-tree/nvim-web-devicons" },
      -- or if using mini.icons/mini.nvim
      -- dependencies = { "echasnovski/mini.icons" },
      opts = {}
    },
    {
      "sindrets/diffview.nvim",
      event = "VeryLazy"
    },
    {
      "mason-org/mason.nvim",
      opts = { ensure_installed = { "goimports", "gofumpt" } },
    }
  }
}
