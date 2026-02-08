return {
	{
		"saghen/blink.cmp",
		-- optional: provides snippets for the snippet source
		dependencies = {
			"rafamadriz/friendly-snippets",
			"williamboman/mason.nvim",
		},

		-- use a release tag to download pre-built binaries
		version = "*",

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				preset = "super-tab", -- use tab to accept suggestions, arrows for navigation
				["<CR>"] = { "accept", "fallback" },
			},

			signature = { enabled = true },

			cmdline = {
				keymap = {
					["<Tab>"] = { "show", "accept" },
					["<Up>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },
				},
				completion = {
					menu = {
						auto_show = false,
					},
				},
			},

			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},

			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },

		config = function(_, opts)
			local blink_cmp = require("blink.cmp")
			blink_cmp.setup(opts)

			-- LspAttach autocmd for keybindings
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
					vim.cmd([[ command! Format execute 'lua vim.lsp.buf.format()' ]])

					local keymap = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = bufnr, desc = desc })
					end

					keymap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
					keymap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
					keymap("n", "gh", vim.lsp.buf.hover, "Hover Info")
					keymap("n", "K", vim.lsp.buf.hover, "Hover Info")
					keymap("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
					keymap("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
					keymap("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add Workspace Folder")
					keymap("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove Workspace Folder")
					keymap("n", "<leader>wl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, "List Workspace Folders")
					keymap("n", "<leader>D", vim.lsp.buf.type_definition, "Type Definition")
					keymap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
					keymap("n", "gr", function()
						require("telescope.builtin").lsp_references(require("telescope.themes").get_dropdown())
					end, "Find References")
					keymap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
					keymap("n", "<leader>e", vim.diagnostic.open_float, "Show Line Diagnostics")
					keymap("n", "<leader>k", vim.diagnostic.goto_prev, "Previous Diagnostic")
					keymap("n", "<leader>j", vim.diagnostic.goto_next, "Next Diagnostic")
					keymap("n", "<leader>q", vim.diagnostic.setloclist, "Quickfix Diagnostics")
					keymap("n", "<leader>so", function()
						require("telescope.builtin").lsp_document_symbols()
					end, "Document Symbols")
				end,
			})

			-- Configure LSP servers with Blink capabilities using native vim.lsp.config
			local servers = {
				clangd = {
					filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "hpp" },
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
						"--completion-style=detailed",
						"--header-insertion=iwyu",
						"--compile-commands-dir=build",
					},
					init_options = {
						clangdFileStatus = true,
					},
				},
				rust_analyzer = {},
				pyright = {},
				ts_ls = {},
				gopls = {},
				lua_ls = {},
				buf_ls = {},
				yamlls = {},
				nil_ls = {},
			}

			for server, config in pairs(servers) do
				config.capabilities = blink_cmp.get_lsp_capabilities(config.capabilities)
				vim.lsp.config(server, config)
			end
			vim.lsp.enable(vim.tbl_keys(servers))
		end,
	},
}
