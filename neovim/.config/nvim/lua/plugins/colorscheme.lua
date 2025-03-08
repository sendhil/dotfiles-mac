return {
    -- the colorscheme should be available when starting Neovim
    {
        "folke/tokyonight.nvim",
        lazy = false,    -- make sure we load this during startup if it is your main colorscheme
        priority = 1000, -- make sure to load this before all the other start plugins
        config = function()
            -- load the colorscheme here
            vim.cmd([[colorscheme tokyonight]])
        end,
    },
    { "rakr/vim-one" },
    { "shaunsingh/nord.nvim" },
    { "navarasu/onedark.nvim" },
    { "catppuccin/nvim" },
    { "cpea2506/one_monokai.nvim" },
    { "marko-cerovac/material.nvim" },
    { "sainnhe/sonokai" },
    { "sainnhe/everforest" },
    { "rmehri01/onenord.nvim" },
    { "overcache/NeoSolarized" },
}
