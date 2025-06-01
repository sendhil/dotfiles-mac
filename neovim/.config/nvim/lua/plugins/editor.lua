return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufWritePost", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			signs_staged = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
			},
			-- on_attach = function(buffer)
			--   local gs = package.loaded.gitsigns

			--   local function map(mode, l, r, desc)
			--     vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
			--   end

			--   -- stylua: ignore start
			--   map("n", "]h", function()
			--     if vim.wo.diff then
			--       vim.cmd.normal({ "]c", bang = true })
			--     else
			--       gs.nav_hunk("next")
			--     end
			--   end, "Next Hunk")
			--   map("n", "[h", function()
			--     if vim.wo.diff then
			--       vim.cmd.normal({ "[c", bang = true })
			--     else
			--       gs.nav_hunk("prev")
			--     end
			--   end, "Prev Hunk")
			--   map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
			--   map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
			--   map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
			--   map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
			--   map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
			--   map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
			--   map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
			--   map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
			--   map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
			--   map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
			--   map("n", "<leader>ghd", gs.diffthis, "Diff This")
			--   map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
			--   map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
			-- end,
		},
	},
	-- better diagnostics list and others
	{
		"folke/trouble.nvim",
		cmd = { "Trouble" },
		opts = {
			modes = {
				lsp = {
					win = { position = "right" },
				},
			},
		},
		keys = {
			{ "\\t", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
			{
				"<leader>cS",
				"<cmd>Trouble lsp toggle<cr>",
				desc = "LSP references/definitions/... (Trouble)",
			},
			{ "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
			{
				"[q",
				function()
					if require("trouble").is_open() then
						require("trouble").prev({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.cmd.cprev)
						if not ok then
							vim.notify(err, vim.log.levels.ERROR)
						end
					end
				end,
				desc = "Previous Trouble/Quickfix Item",
			},
			{
				"]q",
				function()
					if require("trouble").is_open() then
						require("trouble").next({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.cmd.cnext)
						if not ok then
							vim.notify(err, vim.log.levels.ERROR)
						end
					end
				end,
				desc = "Next Trouble/Quickfix Item",
			},
		},
	},

	-- Finds and lists all of the TODO, HACK, BUG, etc comment
	-- in your project and loads them into a browsable list.
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		event = { "BufReadPost", "BufWritePost", "BufNewFile" },
		opts = {},
    -- stylua: ignore
    keys = {
      { "]t",         function() require("todo-comments").jump_next() end, desc = "Next Todo Comment" },
      { "[t",         function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>",                      desc = "Todo (Trouble)" },
    },
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {
			indent = { char = "|" },
			exclude = {
				buftypes = { "terminal" },
			},
			scope = {
				enabled = false,
			},
		},
	},
	{
		"tpope/vim-commentary",
		event = { "VeryLazy" },
		keys = {
			{ "\\\\", "<cmd>Commentary<CR>", mode = "x", desc = "Toggle comment (visual mode)" },
			{ "\\\\", "<cmd>Commentary<CR>", mode = "n", desc = "Toggle comment (normal mode)" },
		},
	},
	{
		"tpope/vim-repeat",
		event = { "VeryLazy" },
	},
	{
		"tpope/vim-surround",
		event = { "VeryLazy" },
	},
	{
		"ggandor/leap.nvim",
		event = { "VeryLazy" },

		-- keep Leap’s normal default mappings
		config = function()
			require("leap").set_default_mappings()
		end,

		-- ── key‑bindings ──────────────────────────────────────────────────────────────
		keys = {
			-- clever‑R   (incremental Treesitter node selection)
			{
				"R",
				function()
					local leap = require("leap")

					-- copy the plugin defaults so we don’t mutate them globally
					local sk = vim.deepcopy(leap.opts.special_keys)
					local sl = {}

					-- make R/r behave like “repeat next/prev target”
					sk.next_target = vim.fn.flatten(vim.list_extend({ "R" }, { sk.next_target }))
					sk.prev_target = vim.fn.flatten(vim.list_extend({ "r" }, { sk.prev_target }))

					-- keep safe_labels, but drop the two traversal keys we just added
					for _, label in ipairs(vim.deepcopy(leap.opts.safe_labels)) do
						if label ~= "R" and label ~= "r" then
							table.insert(sl, label)
						end
					end

					-- fire up Leap’s incremental Treesitter node selector
					require("leap.treesitter").select({
						opts = { special_keys = sk, safe_labels = sl },
					})
				end,
				mode = { "n", "x", "o" },
				desc = "Leap TS incremental select (clever‑R)",
			},
		},
	},
	{
		"akinsho/toggleterm.nvim",
		event = { "VeryLazy" },
		version = "*",
		config = function()
			require("toggleterm").setup({
				open_mapping = [[<C-\>]], -- Bind Ctrl-\ to toggle the terminal'
				shade_terminals = false,
			})

			-- Custom command to toggle floating terminal
			vim.api.nvim_create_user_command("ToggleFloat", function()
				vim.cmd("ToggleTerm direction=float")
			end, {})

			-- Function to set terminal-specific key mappings
			function _G.set_terminal_keymaps()
				local opts = { noremap = true, silent = true }
				local keymap = vim.api.nvim_buf_set_keymap

				keymap(0, "t", "<esc>", [[<C-\><C-n>]], opts) -- Escape to normal mode
				keymap(0, "t", "jk", [[<C-\><C-n>]], opts) -- Alternative escape
				keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts) -- Move left
				keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts) -- Move down
				keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts) -- Move up
				keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts) -- Move right
			end

			-- Apply terminal mappings when a terminal buffer is opened
			vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
		end,
	},
	{
		"nvim-tree/nvim-tree.lua",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- Optional, for file icons
		config = function()
			-- Load and configure nvim-tree
			local nvim_tree = require("nvim-tree")

			nvim_tree.setup({
				hijack_netrw = true, -- Replaces netrw with nvim-tree
				update_focused_file = {
					enable = true,
					update_cwd = true,
				},
				view = {
					width = 35,
					side = "left",
				},
			})

			-- Keybinding to Toggle NvimTree
			vim.keymap.set("n", "<leader>ew", function()
				require("nvim-tree.api").tree.toggle()
			end, { noremap = true, silent = true, desc = "Toggle NvimTree" })
		end,
	},
	-- Lua
	{
		"folke/twilight.nvim",
		keys = {
			{ "\\T", "<cmd>Twilight<CR>", desc = "Toggle Twilight" },
		},
	},
	{
		"folke/zen-mode.nvim",
		keys = {
			{ "\\z", "<cmd>ZenMode<CR>", desc = "Toggle Zen Mode" },
		},
		opts = {
			plugins = {
				twilight = { enabled = false },
			},
		},
	},
	{
		"RRethy/vim-illuminate",
	},
	{
		"kdheepak/lazygit.nvim",
		lazy = true,
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		-- setting the keybinding for LazyGit with 'keys' is recommended in
		-- order to load the plugin when the command is run for the first time
		keys = {
			{ "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = { "BufReadPost", "BufWritePost", "BufNewFile" },
	},
	{
		"Pocco81/HighStr.nvim",
		cmd = { "HSHighlight", "HSRmHighlight", "HSExport", "HSImport" },
	},
	{
		"MattesGroeger/vim-bookmarks",
		dependencies = { "nvim-telescope/telescope-vim-bookmarks.nvim" },
		keys = {
			{ "<Leader>bt", "<Plug>BookmarkToggle", mode = "n", desc = "Toggle Bookmark" },
			{ "<Leader>ba", "<Plug>BookmarkAnnotate", mode = "n", desc = "Annotate Bookmark" },
			{
				"<Leader>bl",
				"<cmd>Telescope vim_bookmarks current_file<CR>",
				mode = "n",
				desc = "List Bookmarks (Current File)",
			},
			{
				"<Leader>bL",
				"<cmd>Telescope vim_bookmarks all<CR>",
				mode = "n",
				desc = "List Bookmarks (All Files)",
			},
			{ "<Leader>bj", "<Plug>BookmarkNext", mode = "n", desc = "Next Bookmark" },
			{ "<Leader>bk", "<Plug>BookmarkPrev", mode = "n", desc = "Previous Bookmark" },
		},
	},
	{
		"sindrets/winshift.nvim",
		event = "VeryLazy",
		keys = {
			{ "<C-W>m", "<Cmd>WinShift<CR>", mode = "n", desc = "Activate WinShift" },
		},
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = "VeryLazy",
		config = function()
			local ufo = require("ufo")

			vim.o.foldcolumn = "1" -- Show fold column
			vim.o.foldlevel = 99 -- Start with all folds open
			vim.o.foldlevelstart = 99 -- Open most folds on start
			vim.o.foldenable = true -- Enable folding

			-- Keybindings for UFO folding
			vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
			vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
			vim.keymap.set("n", "<space>", "za", { desc = "Toggle fold" })

			-- Setup UFO with Treesitter and Indent as providers
			ufo.setup({
				provider_selector = function(bufnr, filetype, buftype)
					return { "treesitter", "indent" }
				end,
			})
		end,
	},
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatorProcessList",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
		},
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "rcarriga/nvim-dap-ui" },
			{ "theHamsta/nvim-dap-virtual-text" },
			{ "leoluz/nvim-dap-go" },
			{ "nvim-neotest/nvim-nio" },
		},

		config = function()
			---------------------------------------------------------------------------
			-- 1.  Basic setups -------------------------------------------------------
			---------------------------------------------------------------------------
			local dap, dapui = require("dap"), require("dapui")

			dapui.setup({}) -- defaults are fine to start
			require("nvim-dap-virtual-text").setup({})
			require("dap-go").setup({}) -- populates ‘debug test’ etc. configs

			-- Auto-open/close UI panels
			dap.listeners.after.event_initialized["dapui_auto"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_auto"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_auto"] = function()
				dapui.close()
			end

			dap.adapters.go = function(callback, config)
				if config.request == "attach" then
					local port = config.port or tonumber(vim.fn.input("Delve TCP port › ", "2345"))
					callback({ type = "server", host = config.host or "127.0.0.1", port = port })
				else
					callback({
						type = "server",
						host = "127.0.0.1",
						port = "${port}",
						executable = {
							command = "dlv",
							args = { "dap", "-l", "127.0.0.1:${port}" },
						},
					})
				end
			end

			dap.configurations.go = {
				{
					name = "Attach (remote: localhost:2345)",
					type = "go",
					request = "attach",
					mode = "remote",
					host = "127.0.0.1",
					port = 2345,
					-- optional: map paths if the code runs in a container
					-- substitutePath = { { from = "${workspaceFolder}", to =  "/app" } },
				},
				-- dap-go already adds: “Debug ↪ file”, “Debug ↪ test”, “Debug ↪ pkg” …
			}

			---------------------------------------------------------------------------
			-- 4.  Handy keymaps ------------------------------------------------------
			---------------------------------------------------------------------------
			local map = vim.keymap.set
			map("n", "<F5>", dap.continue, { desc = "DAP continue/attach" })
			map("n", "<F10>", dap.step_over, { desc = "DAP step over" })
			map("n", "<F11>", dap.step_into, { desc = "DAP step into" })
			map("n", "<F12>", dap.step_out, { desc = "DAP step out" })
			map("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP toggle bp" })
			map("n", "<leader>B", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition › "))
			end, { desc = "DAP conditional bp" })
			map("n", "<leader>du", dapui.toggle, { desc = "DAP UI toggle" })

			vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "", linehl = "", numhl = "" })
		end,
	},
	{
		"leoluz/nvim-dap-go",
		ft = "go",
		dependencies = "mfussenegger/nvim-dap",
		config = true,
	},
	{
		"ray-x/go.nvim",
		dependencies = { -- optional packages
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("go").setup()

			local format_sync_grp = vim.api.nvim_create_augroup("goimports", {})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*.go",
				callback = function()
					require("go.format").goimports()
				end,
				group = format_sync_grp,
			})
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
	},
	{
		"athar-qadri/scratchpad.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-lua/plenary.nvim" }, -- don't forget to add this one if you don't have it yet!
		config = function()
			require("scratchpad"):setup({
				settings = {
					sync_on_ui_close = true,
				},
			})
		end,
		keys = {
			{
				"\\s",
				function()
					local scratchpad = require("scratchpad")
					scratchpad.ui:new_scratchpad()
				end,
				desc = "open scratchpad",
			},
		},
	},
	{
		"tveskag/nvim-blame-line",
		event = "VeryLazy",
		keys = {
			{ "<Leader>gb", "<cmd>ToggleBlameLine<CR>", mode = "n", desc = "Toggle Git Blame" },
		},
	},
	{
		"almo7aya/openingh.nvim",
		event = "VeryLazy",
	},
	{
		"pwntester/octo.nvim",
		commit = "f09ff9413652e3c06a6817ba6284591c00121fe0",
		pin = true,
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("octo").setup({
				suppress_missing_scope = {
					projects_v2 = true,
				},
			})
		end,
	},
}
