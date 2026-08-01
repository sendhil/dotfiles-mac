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
      'chomosuke/typst-preview.nvim',
      lazy = false, -- or ft = 'typst'
      version = '1.*',
      opts = {},
      config = function(_, opts)
        require('typst-preview').setup(opts)
        require('typst_tdf').setup()
      end,
    }
  }
}
