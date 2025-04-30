return {
    {
        "folke/which-key.nvim",
        opts = {
            spec = {
                { "<BS>",      desc = "Decrement Selection", mode = "x" },
                { "<c-space>", desc = "Increment Selection", mode = { "x", "n" } },
            },
        },
    },

    -- Treesitter is a new parser generator tool that we can
    -- use in Neovim to power faster and more accurate
    -- syntax highlighting.
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "c", "lua", "rust", "go", "python" },
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                rainbow = {
                    enable = true,
                    extended_mode = true,
                    max_file_lines = nil,
                },
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("nvim-treesitter.configs").setup({
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["am"] = "@function.outer",
                            ["im"] = "@function.inner",
                            ["al"] = "@class.outer",
                            ["il"] = { query = "@class.inner", desc = "Select inner part of a class region" },
                            ["ab"] = "@block.outer",
                            ["ib"] = "@block.inner",
                            ["ad"] = "@conditional.outer",
                            ["id"] = "@conditional.inner",
                            ["ao"] = "@loop.outer",
                            ["io"] = "@loop.inner",
                            ["aa"] = "@parameter.outer",
                            ["ia"] = "@parameter.inner",
                            ["af"] = "@call.outer",
                            ["if"] = "@call.inner",
                            ["ac"] = "@comment.outer",
                            ["at"] = "@attribute.outer",
                            ["it"] = "@attribute.inner",
                            ["as"] = "@statement.outer",
                            ["is"] = "@statement.outer",
                        },
                        include_surrounding_whitespace = false,
                    },
                    lsp_interop = {
                        enable = true,
                        border = 'none',
                        floating_preview_opts = {},
                        peek_definition_code = {
                            ["<leader>df"] = "@function.outer",
                            ["<leader>dF"] = "@class.outer",
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next = {
                            [")m"] = "@function.outer",
                            [")c"] = "@comment.outer",
                            [")a"] = "@parameter.inner",
                            [")b"] = "@block.outer",
                            [")C"] = "@class.outer",
                        },
                        swap_previous = {
                            ["(m"] = "@function.outer",
                            ["(c"] = "@comment.outer",
                            ["(a"] = "@parameter.inner",
                            ["(b"] = "@block.outer",
                            ["(C"] = "@class.outer",
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            ["]m"] = "@function.outer",
                            ["]f"] = "@call.outer",
                            ["]d"] = "@conditional.outer",
                            ["]o"] = "@loop.outer",
                            ["]s"] = "@statement.outer",
                            ["]a"] = "@parameter.outer",
                            ["]c"] = "@comment.outer",
                            ["]b"] = "@block.outer",
                            ["]l"] = { query = "@class.outer", desc = "next class start" },
                            ["]t"] = "@attribute.outer",
                            ["]]m"] = "@function.inner",
                            ["]]f"] = "@call.inner",
                            ["]]d"] = "@conditional.inner",
                            ["]]o"] = "@loop.inner",
                            ["]]a"] = "@parameter.inner",
                            ["]]b"] = "@block.inner",
                            ["]]l"] = { query = "@class.inner", desc = "next class start" },
                            ["]]t"] = "@attribute.inner",
                        },
                        goto_next_end = {
                            ["]M"] = "@function.outer",
                            ["]F"] = "@call.outer",
                            ["]D"] = "@conditional.outer",
                            ["]O"] = "@loop.outer",
                            ["]S"] = "@statement.outer",
                            ["]A"] = "@parameter.outer",
                            ["]C"] = "@comment.outer",
                            ["]B"] = "@block.outer",
                            ["]L"] = "@class.outer",
                            ["]T"] = "@attribute.outer",
                            ["]]M"] = "@function.inner",
                            ["]]F"] = "@call.inner",
                            ["]]D"] = "@conditional.inner",
                            ["]]O"] = "@loop.inner",
                            ["]]A"] = "@parameter.inner",
                            ["]]B"] = "@block.inner",
                            ["]]L"] = "@class.inner",
                            ["]]T"] = "@attribute.inner",
                        },
                        goto_previous_start = {
                            ["[m"] = "@function.outer",
                            ["[f"] = "@call.outer",
                            ["[d"] = "@conditional.outer",
                            ["[o"] = "@loop.outer",
                            ["[s"] = "@statement.outer",
                            ["[a"] = "@parameter.outer",
                            ["[c"] = "@comment.outer",
                            ["[b"] = "@block.outer",
                            ["[l"] = "@class.outer",
                            ["[t"] = "@attribute.outer",
                            ["[[m"] = "@function.inner",
                            ["[[f"] = "@call.inner",
                            ["[[d"] = "@conditional.inner",
                            ["[[o"] = "@loop.inner",
                            ["[[a"] = "@parameter.inner",
                            ["[[b"] = "@block.inner",
                            ["[[l"] = "@class.inner",
                            ["[[t"] = "@attribute.inner",
                        },
                        goto_previous_end = {
                            ["[M"] = "@function.outer",
                            ["[F"] = "@call.outer",
                            ["[D"] = "@conditional.outer",
                            ["[O"] = "@loop.outer",
                            ["[S"] = "@statement.outer",
                            ["[A"] = "@parameter.outer",
                            ["[C"] = "@comment.outer",
                            ["[B"] = "@block.outer",
                            ["[L"] = "@class.outer",
                            ["[T"] = "@attribute.outer",
                            ["[[M"] = "@function.inner",
                            ["[[F"] = "@call.inner",
                            ["[[D"] = "@conditional.inner",
                            ["[[O"] = "@loop.inner",
                            ["[[A"] = "@parameter.inner",
                            ["[[B"] = "@block.inner",
                            ["[[L"] = "@class.inner",
                            ["[[T"] = "@attribute.inner",
                        },
                    },
                },
            })
            local ts_repeat_move = require "nvim-treesitter.textobjects.repeatable_move"

            -- Repeat movement with ; and ,
            -- ensure ; goes forward and , goes backward regardless of the last direction
            -- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
            -- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

            -- vim way: ; goes to the direction you were moving.
            vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
            vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)
        end,
    },
    { 'nvim-treesitter/nvim-treesitter-context', dependencies = { 'nvim-treesitter/nvim-treesitter' } },

    -- Automatically add closing tags for HTML and JSX
    {
        "windwp/nvim-ts-autotag",
        event = { "BufReadPost", "BufWritePost", "BufNewFile", "VeryLazy" },
        opts = {},
    },
}
