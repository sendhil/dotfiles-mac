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
				dependencies = { "nvim-treesitter/nvim-treesitter" },
				opts = {
					preview = {
						filetypes = { "markdown", "codecompanion", "octo" },
						ignore_buftypes = {},
					},
				},
			},
			"ravitemer/codecompanion-history.nvim",
		},
		config = function()
			require("codecompanion").setup({
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
							add_slash_command = true,
						},
					},
				},
				strategies = {
					chat = {
						adapter = vim.env.CODECOMPANION_ADAPTER or "openai",
						slash_commands = {
							["buffer"] = {
								keymaps = {
									modes = {
										n = { "gb" },
									},
								},
							},
						},
						tools = {
							opts = {
								auto_submit_errors = true, -- Send any errors to the LLM automatically?
								auto_submit_success = true, -- Send any successful output to the LLM automatically?
								default_tools = {
									"cmd_runner",
									"create_file",
									"file_search",
									"get_changed_files",
									"grep_search",
									"insert_edit_into_file",
									"read_file",
									"fetch_webpage",
									"search_web",
								},
							},
						},
					},
					inline = {
						adapter = vim.env.CODECOMPANION_ADAPTER or "openai",
					},
					cmd = {
						adapter = vim.env.CODECOMPANION_ADAPTER or "openai",
					},
				},
				adapters = {
					openai = function()
						return require("codecompanion.adapters").extend("openai", {
							url = vim.env.CODECOMPANION_OPENAI_URL or nil,
							schema = {
								model = {
									default = "o3-mini",
								},
							},
						})
					end,
					openai_compatible = function()
						return require("codecompanion.adapters").extend("openai_compatible", {
							env = {
								url = vim.env.CODECOMPANION_OPENAI_COMPATIBLE_URL or nil,
								api_key = vim.env.CODECOMPANION_OPENAI_COMPATIBLE_URL_API_KEY or nil,
							},
							schema = {
								model = {
									default = "anthropic.claude-3-7-sonnet-20250219-v1:0",
								},
							},
						})
					end,
					tavily = function()
						return require("codecompanion.adapters").extend("tavily", {
							env = {
								api_key = vim.env.TAVILY_API_KEY or nil,
							},
						})
					end,
					jina = function()
						return require("codecompanion.adapters").extend("jina", {
							env = {
								api_key = vim.env.JINA_API_KEY or nil,
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
