return {
	{
		"folke/which-key.nvim",
		opts = {
			spec = {
				{ "<BS>", desc = "Decrement Selection", mode = "x" },
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
				ensure_installed = { "c", "lua", "rust", "go", "python", "markdown", "markdown_inline" },
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
						border = "none",
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
							["]/"] = "@comment.outer",
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
							["[/"] = "@comment.outer",
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
			local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

			-- Repeat movement with ; and ,
			-- ensure ; goes forward and , goes backward regardless of the last direction
			-- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
			-- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

			-- vim way: ; goes to the direction you were moving.
			vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
			vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)
		end,
	},
	{
	"nvim-treesitter/nvim-treesitter-context",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {
		enable = true, -- Enable this plugin (Can be enabled/disabled with `:TSContextToggle`)
		max_lines = 3, -- How many lines the window should span. Values <= 0 mean no limit.
		trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
		patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
			-- For all filetypes
			-- Note that setting an entry here replaces all other patterns for this entry.
			-- By setting the 'default' entry below, you can control which nodes you want to
			-- appear in the context window.
			default = {
				'class',
				'function',
				'method',
				'for', -- These won't appear in the context
				'while',
				'if',
				'switch',
				'case',
			},
		},
		exact_patterns = {
			-- Example for a specific filetype with Lua patterns
			-- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
			-- exactly match "impl_item" only)
			-- rust = true,
		},
		zindex = 20, -- The Z-index of the context window
		mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
		separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
	},
},

	-- Automatically add closing tags for HTML and JSX
	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPost", "BufWritePost", "BufNewFile", "VeryLazy" },
		opts = {},
	},
}
