return {
	{
		"nanozuki/tabby.nvim",
		event = "VeryLazy",
		config = function()
			require("tabby").setup({
				preset = "active_wins_at_tail",
				option = {
					nerdfont = true, -- whether use nerdfont
					lualine_theme = "onedark", -- lualine theme name
					tab_name = {
						name_fallback = function(tabid)
							local win = vim.api.nvim_tabpage_get_win(tabid)
							local buf = vim.api.nvim_win_get_buf(win)
							local full_path = vim.api.nvim_buf_get_name(buf)

							if full_path == "" then
								return tabid
							end

							return vim.fn.fnamemodify(full_path, ":t")
						end,
					},
					buf_name = {
						mode = "unique", -- or 'relative', 'tail', 'shorten'
					},
				},
			})
		end,
	},
	-- {
	-- 	"akinsho/bufferline.nvim",

	-- 	event = "VeryLazy",
	-- 	keys = {
	-- 		{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
	-- 		{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
	-- 		{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
	-- 		{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
	-- 	},
	-- 	opts = {
	-- 		options = {
	-- 			mode = "tabs",
	-- 			diagnostics = "nvim_lsp",
	-- 			separator_style = "slant",
	-- 			offsets = { { filetype = "NvimTree", text = "File Explorer" } },
	-- 			diagnostics_indicator = function(count, level, diagnostics_dict, context)
	-- 				local s = " "
	-- 				for e, n in pairs(diagnostics_dict) do
	-- 					local sym = e == "error" and " " or (e == "warning" and " " or "")
	-- 					s = s .. n .. sym
	-- 				end
	-- 				return s
	-- 			end,
	-- 		},
	-- 	},
	-- 	config = function(_, opts)
	-- 		require("bufferline").setup(opts)
	-- 		-- Fix bufferline when restoring a session
	-- 		vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
	-- 			callback = function()
	-- 				vim.schedule(function()
	-- 					pcall(nvim_bufferline)
	-- 				end)
	-- 			end,
	-- 		})
	-- 	end,
	-- },
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "wombat",
			},
		},
	},
	{
		"j-hui/fidget.nvim",
	},
	{
		"rcarriga/nvim-notify",
		lazy = true, -- Load lazily
		event = "VeryLazy", -- Load on UI event
		config = function()
			local notify = require("notify")

			-- Set up notify as the default notification system
			vim.notify = notify

			notify.setup({
				stages = "fade", -- Animation style: fade, slide, static
				timeout = 3000, -- Duration before notification disappears
				-- background_colour = "Normal", -- Use normal background
				background_colour = "#000000", -- Use normal background
				fps = 60, -- Animation smoothness
				icons = {
					ERROR = "",
					WARN = "",
					INFO = "",
					DEBUG = "",
					TRACE = "✎",
				},
			})

			-- Optional: Set keybinding to show notification history
			vim.keymap.set("n", "<leader>nh", notify.history, { desc = "Show Notification History" })
		end,
	},
	{
		"kevinhwang91/nvim-bqf",
		event = "VeryLazy",
	},
}
