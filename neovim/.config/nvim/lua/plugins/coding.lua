return {
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
		-- use opts = {} for passing setup options
		-- this is equivalent to setup({}) function
	},
	{
		"olimorris/codecompanion.nvim",
		cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
		opts = {
			extensions = {
				history = {
					enabled = true,
					opts = {
						keymap = "gh",
						save_chat_keymap = "sc",
						auto_save = false,
						auto_generate_title = true,
						continue_last_chat = false,
						delete_on_clearing_chat = false,
						picker = "snacks",
						enable_logging = false,
						dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
					},
				},
				mcphub = {
					callback = "mcphub.extensions.codecompanion",
					opts = {
						make_vars = true,
						make_slash_commands = true,
						show_result_in_chat = true,
					},
				},
				vectorcode = {
					opts = {
						add_tool = true,
					},
				},
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			{
				"ravitemer/mcphub.nvim", -- Manage MCP servers
				cmd = "MCPHub",
				build = "npm install -g mcp-hub@latest",
				config = true,
			},
			{
				"Davidyz/VectorCode", -- Index and search code in your repositories
				version = "*",
				build = "pipx upgrade vectorcode",
				dependencies = { "nvim-lua/plenary.nvim" },
			},
			{
				"HakonHarnes/img-clip.nvim", -- Share images with the chat buffer
				event = "VeryLazy",
				cmd = "PasteImage",
				opts = {
					filetypes = {
						codecompanion = {
							prompt_for_file_name = false,
							template = "[Image]($FILE_PATH)",
							use_absolute_path = true,
						},
					},
				},
			},
			{
				"OXY2DEV/markview.nvim",
				lazy = false,
				opts = {
					preview = {
						filetypes = { "markdown", "codecompanion", "octo" },
						ignore_buftypes = {},
					},
				},
			},
		},
		config = function()
			require("codecompanion").setup({
				strategies = {
					chat = {
						adapter = "openai",
						slash_commands = {
							["buffer"] = {
								keymaps = {
									modes = {
										n = { "gb" },
									},
								},
							},
						},
					},
					inline = {
						adapter = "openai",
					},
					cmd = {
						adapter = "openai",
					},
				},
				adapters = {
					openai = function()
						return require("codecompanion.adapters").extend("openai", {
							url = vim.env.CODECOMPANION_URL or nil,
							schema = {
								model = {
									default = "o3-mini",
								},
							},
						})
					end,
				},
			})
		end,
		init = function()
			require("plugins.codecompanion.fidget-spinner"):init()
		end,
		keys = {
			{
				"<Leader>aa",
				"<cmd>CodeCompanionActions<CR>",
				desc = "Open the action palett",
				mode = { "n", "v" },
			},
			{
				"<Leader>at",
				"<cmd>CodeCompanionChat Toggle<CR>",
				desc = "Toggle a chat buffer",
				mode = { "n", "v" },
			},
			{
				"<Leader>ac",
				"<cmd>CodeCompanionChat Add<CR>",
				desc = "Add code to a chat buffer",
				mode = { "v" },
			},
		},
	},
}
