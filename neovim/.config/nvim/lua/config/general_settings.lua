-- Set UTF-8 encoding
vim.o.encoding = "utf-8"

-- Use system clipboard
vim.o.clipboard = "unnamedplus"

-- Searching
vim.o.ignorecase = true -- Case-insensitive search
vim.o.incsearch = true  -- Incremental search
vim.o.hlsearch = true   -- Highlight search results

-- Display settings
vim.o.number = true    -- Show line numbers
vim.o.ruler = true     -- Show cursor position
vim.o.showmode = false -- Hide mode display (redundant with statusline)

-- Tabs & indentation
vim.o.tabstop = 2      -- Number of spaces per tab
vim.o.shiftwidth = 2   -- Number of spaces for auto-indent
vim.o.softtabstop = 2  -- Number of spaces for soft tabstop
vim.o.expandtab = true -- Convert tabs to spaces

-- Buffer behavior
vim.o.hidden = true -- Allow buffer switching without saving

-- Disable backup files
vim.o.backup = false
vim.o.writebackup = false

-- Set swap, backup, and undo directories
if vim.fn.has("win32") == 1 then
    vim.o.directory = vim.fn.expand("$HOME/temp//")
    vim.o.backupdir = vim.fn.expand("$HOME/temp//")
    vim.o.undodir = vim.fn.expand("$HOME/temp//")
elseif vim.fn.has("unix") == 1 then
    vim.o.directory = "/tmp/"
    vim.o.backupdir = "/tmp/"
    vim.o.undodir = "/tmp/"
end

-- Backspace behavior (only necessary on Windows)
if vim.fn.has("win32") == 1 then
    vim.o.backspace = "indent,eol,start"
end

-- Font settings
-- vim.o.guifont = "Fira Code Nerd Font:h16"
vim.o.guifont = "MesloLGS NF:h16"
if vim.fn.has("gui_macvim") == 1 then
    vim.o.guifont = "Fira Code:h16"
    vim.o.macligatures = true
end

-- Colors & UI Enhancements
vim.opt.termguicolors = true
vim.opt.listchars = { tab = "▸ ", eol = "¬" }
vim.g.NVIM_TUI_ENABLE_TRUE_COLOR = 1

-- Set colorscheme
vim.cmd("colorscheme tokyonight")
vim.o.background = "dark"
