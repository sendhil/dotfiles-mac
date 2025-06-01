return {
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{ "tom-anders/telescope-vim-bookmarks.nvim" },
	{ "nvim-telescope/telescope-file-browser.nvim" },
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		-- or                              , branch = '0.1.x',
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-fzf-native.nvim",
			"tom-anders/telescope-vim-bookmarks.nvim",
			"nvim-telescope/telescope-file-browser.nvim",
		},
		config = function()
			local actions = require("telescope.actions")

			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
							["<esc>"] = actions.close, -- One <Esc> to quit
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
							["<leader>q"] = actions.send_to_qflist + actions.open_qflist,
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
							["<C-l>"] = actions.send_selected_to_loclist + actions.open_loclist,
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
		},
	},
}
