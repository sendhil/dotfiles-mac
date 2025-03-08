return {
    {
        'saghen/blink.cmp',
        -- optional: provides snippets for the snippet source
        dependencies = 'rafamadriz/friendly-snippets',

        -- use a release tag to download pre-built binaries
        version = '*',
        -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
        -- build = 'cargo build --release',
        -- If you use nix, you can build from source using latest nightly rust with:
        -- build = 'nix run .#build-plugin',

        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept, C-n/C-p for up/down)
            -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys for up/down)
            -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
            --
            -- All presets have the following mappings:
            -- C-space: Open menu or open docs if already open
            -- C-e: Hide menu
            -- C-k: Toggle signature help
            --
            -- See the full "keymap" documentation for information on defining your own keymap.
            keymap = {
                preset = 'default',
                ['<CR>'] = { 'accept', 'fallback' },
            },

            signature = { enabled = true },

            cmdline = {
                keymap = {
                    ['<Tab>'] = { 'show', 'accept' },
                    ['<Up>'] = { 'select_prev', 'fallback' },
                    ['<Down>'] = { 'select_next', 'fallback' },
                },
                completion = {
                    menu = {
                        auto_show = true,
                    },
                }
            },

            appearance = {
                -- Sets the fallback highlight groups to nvim-cmp's highlight groups
                -- Useful for when your theme doesn't support blink.cmp
                -- Will be removed in a future release
                use_nvim_cmp_as_default = true,
                -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- Adjusts spacing to ensure icons are aligned
                nerd_font_variant = 'mono'
            },

            -- Default list of enabled providers defined so that you can extend it
            -- elsewhere in your config, without redefining it, due to `opts_extend`
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },

            -- Blink.cmp uses a Rust fuzzy matcher by default for typo resistance and significantly better performance
            -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
            -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
            --
            -- See the fuzzy documentation for more information
            fuzzy = { implementation = "prefer_rust_with_warning" }
        },
        opts_extend = { "sources.default" }
    },

    -- LSP servers and clients communicate which features they support through "capabilities".
    --  By default, Neovim supports a subset of the LSP specification.
    --  With blink.cmp, Neovim has _more_ capabilities which are communicated to the LSP servers.
    --  Explanation from TJ: https://youtu.be/m8C0Cq9Uv9o?t=1275
    --
    -- This can vary by config, but in general for nvim-lspconfig:
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "saghen/blink.cmp" },
        opts = {
            servers = {
                clangd = {},
                rust_analyzer = {},
                pyright = {},
                ts_ls = {},
                gopls = {},
                lua_ls = {},
                sourcekit = {},
            },
        },
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            local blink_cmp = require("blink.cmp")

            -- Common on_attach function for all servers
            local function on_attach(_, bufnr)
                vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
                vim.cmd [[ command! Format execute 'lua vim.lsp.buf.format()' ]]

                local keymap = function(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = bufnr, desc = desc })
                end

                -- LSP Keybindings
                keymap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
                keymap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
                keymap("n", "gh", vim.lsp.buf.hover, "Hover Info")
                keymap("n", "K", vim.lsp.buf.hover, "Hover Info")
                keymap("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
                keymap("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
                keymap("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add Workspace Folder")
                keymap("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove Workspace Folder")
                keymap("n", "<leader>wl", function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
                    "List Workspace Folders")
                keymap("n", "<leader>D", vim.lsp.buf.type_definition, "Type Definition")
                keymap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
                keymap("n", "gr",
                    function() require("telescope.builtin").lsp_references(require("telescope.themes").get_dropdown()) end,
                    "Find References")
                keymap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
                keymap("n", "<leader>e", vim.diagnostic.open_float, "Show Line Diagnostics")
                keymap("n", "<leader>k", vim.diagnostic.goto_prev, "Previous Diagnostic")
                keymap("n", "<leader>j", vim.diagnostic.goto_next, "Next Diagnostic")
                keymap("n", "<leader>q", vim.diagnostic.setloclist, "Quickfix Diagnostics")
                keymap("n", "<leader>so", function() require("telescope.builtin").lsp_document_symbols() end,
                    "Document Symbols")
            end

            -- Setup LSP servers with Blink capabilities
            for server, config in pairs(opts.servers) do
                config.capabilities = blink_cmp.get_lsp_capabilities(config.capabilities)
                config.on_attach = on_attach
                lspconfig[server].setup(config)
            end
        end,
    }
}
