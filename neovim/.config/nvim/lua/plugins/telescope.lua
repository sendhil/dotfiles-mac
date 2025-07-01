return {
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{ "tom-anders/telescope-vim-bookmarks.nvim" },
	{ "nvim-telescope/telescope-file-browser.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-fzf-native.nvim",
			"tom-anders/telescope-vim-bookmarks.nvim",
			"nvim-telescope/telescope-file-browser.nvim",
		},
		config = function()
			local actions = require("telescope.actions")
			local trouble = require("trouble")

			-- Custom actions that send to qflist/loclist and open Trouble
			local send_to_qflist_and_trouble = function(prompt_bufnr)
				actions.send_to_qflist(prompt_bufnr)
				vim.schedule(function()
					vim.cmd("cclose")
					vim.cmd("Trouble qflist toggle")
				end)
			end

			local send_selected_to_qflist_and_trouble = function(prompt_bufnr)
				actions.send_selected_to_qflist(prompt_bufnr)
				vim.schedule(function()
					vim.cmd("cclose")
					vim.cmd("Trouble qflist toggle")
				end)
			end

			local send_to_loclist_and_trouble = function(prompt_bufnr)
				actions.send_to_loclist(prompt_bufnr)
				vim.schedule(function()
					vim.cmd("lclose")
					vim.cmd("Trouble loclist toggle")
				end)
			end

			local send_selected_to_loclist_and_trouble = function(prompt_bufnr)
				actions.send_selected_to_loclist(prompt_bufnr)
				vim.schedule(function()
					vim.cmd("lclose")
					vim.cmd("Trouble loclist toggle")
				end)
			end

			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
							["<esc>"] = actions.close, -- One <Esc> to quit
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
							["<leader>q"] = send_to_qflist_and_trouble,
							["<leader>l"] = send_to_loclist_and_trouble,
							["<C-q>"] = send_selected_to_qflist_and_trouble,
							["<C-l>"] = send_selected_to_loclist_and_trouble,
						},
					},
					path_display = { "smart" },
				},
				extensions = {
					fzf = {
						fuzzy = true, -- false will only do exact matching
						override_generic_sorter = true, -- override the generic sorter
						override_file_sorter = true, -- override the file sorter
						case_mode = "smart_case", -- smart case matching
					},
				},
			})

			-- To get fzf loaded and working with telescope, you need to call
			-- load_extension, somewhere after setup function:
			require("telescope").load_extension("fzf")
			require("telescope").load_extension("vim_bookmarks")

			-- Custom Telescope picker for Trouble modes
			local pickers = require("telescope.pickers")
			local finders = require("telescope.finders")
			local conf = require("telescope.config").values
			local actions_state = require("telescope.actions.state")

			local trouble_telescope = function(opts)
				opts = opts or {}
				
				-- Define Trouble modes with descriptions
				local modes = {
					{ name = "diagnostics", desc = "Diagnostics" },
					{ name = "fzf", desc = "FzfLua results" },
					{ name = "fzf_files", desc = "FzfLua files" },
					{ name = "loclist", desc = "Location List" },
					{ name = "lsp", desc = "LSP definitions, references, implementations, type definitions, and declarations" },
					{ name = "lsp_command", desc = "LSP Command" },
					{ name = "lsp_declarations", desc = "LSP Declarations" },
					{ name = "lsp_definitions", desc = "LSP Definitions" },
					{ name = "lsp_document_symbols", desc = "Document Symbols" },
					{ name = "lsp_implementations", desc = "LSP Implementations" },
					{ name = "lsp_incoming_calls", desc = "LSP Incoming Calls" },
					{ name = "lsp_outgoing_calls", desc = "LSP Outgoing Calls" },
					{ name = "lsp_references", desc = "LSP References" },
					{ name = "lsp_type_definitions", desc = "LSP Type Definitions" },
					{ name = "qflist", desc = "Quickfix List" },
					{ name = "quickfix", desc = "Quickfix List" },
					{ name = "symbols", desc = "Document Symbols" },
					{ name = "telescope", desc = "Telescope results" },
					{ name = "telescope_files", desc = "Telescope files" },
					{ name = "todo", desc = "Todo Comments" },
				}
				
				pickers.new(opts, {
					prompt_title = "Trouble Modes",
					finder = finders.new_table({
						results = modes,
						entry_maker = function(entry)
							return {
								value = entry.name,
								display = string.format("%-30s %s", entry.name, entry.desc),
								ordinal = entry.name .. " " .. entry.desc,
							}
						end,
					}),
					sorter = conf.generic_sorter(opts),
					attach_mappings = function(prompt_bufnr, map)
						actions.select_default:replace(function()
							actions.close(prompt_bufnr)
							local selection = actions_state.get_selected_entry()
							if selection then
								vim.cmd("Trouble " .. selection.value .. " toggle")
							end
						end)
						return true
					end,
				}):find()
			end

			-- Make it available as a command
			vim.api.nvim_create_user_command("TroubleTelescope", trouble_telescope, {})
		end,
		keys = {
			{
				"<leader>sa",
				function()
					require("telescope.builtin").builtin()
				end,
				desc = "Telescope: Builtin Pickers",
			},
			{
				"<leader><space>",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "Telescope: Buffers",
			},
			{
				"<leader>t",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "Telescope: Find Files",
			},
			{
				"<leader>sb",
				function()
					require("telescope.builtin").current_buffer_fuzzy_find()
				end,
				desc = "Telescope: Fuzzy Find in Buffer",
			},
			{
				"<leader>sh",
				function()
					require("telescope.builtin").help_tags()
				end,
				desc = "Telescope: Help Tags",
			},
			{
				"<leader>sd",
				function()
					require("telescope.builtin").diagnostics()
				end,
				desc = "Telescope: Diagnostics",
			},
			{
				"<leader>f",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "Telescope: Live Grep",
			},
			{
				"<leader>so",
				function()
					require("telescope.builtin").tags({ only_current_buffer = true })
				end,
				desc = "Telescope: Buffer Tags",
			},
			{
				"<leader>.",
				function()
					require("telescope.builtin").lsp_code_actions(require("telescope.themes").get_cursor())
				end,
				desc = "Telescope: Code Actions",
			},
			{
				"<leader>sca",
				function()
					require("telescope.builtin").lsp_code_actions(require("telescope.themes").get_cursor())
				end,
				desc = "Telescope: Code Actions (LSP)",
			},
			{
				"<leader>sr",
				function()
					require("telescope.builtin").lsp_references(require("telescope.themes").get_dropdown())
				end,
				desc = "Telescope: LSP References",
			},
			{
				"gr",
				function()
					require("telescope.builtin").lsp_references(require("telescope.themes").get_dropdown())
				end,
				desc = "Telescope: LSP References (gr)",
			},
			{
				"<C-e>",
				function()
					require("telescope.builtin").oldfiles()
				end,
				desc = "Telescope: Recent Files",
			},
			{
				"<leader>p",
				function()
					require("telescope.builtin").commands()
				end,
				desc = "Telescope: Commands",
			},
			{
				"<leader>sr",
				function()
					require("telescope.builtin").resume()
				end,
				desc = "Telescope: Resume Last Picker",
			},
			{ "<leader>sf", "<cmd>Telescope file_browser<CR>", desc = "Telescope: File Browser" },
			{ "<leader>ga", "<cmd>Octo actions<CR>", desc = "Telescope: GitHub Actions" },
		},
	},
}
