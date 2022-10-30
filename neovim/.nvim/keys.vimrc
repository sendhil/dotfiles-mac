let mapleader=','
if has("win32")
    map <C-e> :MRU<CR>
else
    map <C-e> :History<CR>
endif

" List Navigation
map <expr> <C-n> (empty(getloclist(1))  ? ":cn" : ":lnext")."\n"
map <expr> <C-p> (empty(getloclist(0))  ? ":cp" : ":lp")."\n"

nmap <Leader>f :Telescope live_grep<CR>
nmap <Leader>F :Telescope live_grep

map <leader>ew :NvimTreeToggle<CR>

nmap T :terminal<CR> :startinsert<CR>
nnoremap <leader>ov :exe ':silent !code %'<CR>:redraw!<CR>

map <leader>ct :tabclose<CR>
map <leader>st :tab split<CR>

nmap <leader>. :CtrlPTag<CR> " TODO: Update

nmap <silent> <F5> :set spell!<CR>

nmap \e :NvimTreeToggle<CR>
nmap \t :TroubleToggle<CR>
" nmap \t :TagbarToggle<CR> #TODO - Bind to new plugin

xmap \\ :Commentary<CR>
nmap \\ :Commentary<CR>

nmap <Leader>p :Commands<CR>

" Man Pages
au FileType man nmap gd :Man<CR>

" Ctrl-Space
let g:CtrlSpaceDefaultMappingKey = "<C-space> "

" Telescope Shortcuts
lua << EOF

vim.api.nvim_set_keymap('n', '<leader>sa', [[<cmd>lua require('telescope.builtin').builtin()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader><space>', [[<cmd>lua require('telescope.builtin').buffers()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>t', [[<cmd>lua require('telescope.builtin').find_files()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>sf', [[<cmd>lua require('telescope.builtin').find_files()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>sb', [[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>sh', [[<cmd>lua require('telescope.builtin').help_tags()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>sd', [[<cmd>lua require('telescope.builtin').grep_string()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>sp', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>so', [[<cmd>lua require('telescope.builtin').tags{ only_current_buffer = true }<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>sca', [[<cmd>lua require('telescope.builtin').lsp_code_actions(require('telescope.themes').get_cursor())<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>sr', [[<cmd>lua require('telescope.builtin').lsp_references(require('telescope.themes').get_dropdown())<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gr', [[<cmd>lua require('telescope.builtin').lsp_references(require('telescope.themes').get_dropdown())<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>?', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-e>', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>p', [[<cmd>lua require('telescope.builtin').commands()<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>g', [[<cmd>lua _lazygit_toggle()<CR>]], { noremap = true, silent = true })

-- LSP Shortcuts are in lsp.vimrc atm


local actions = require('telescope.actions')
require('telescope').setup{
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = actions.close, -- One <Esc> in insert mode instead of two to quit
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  }
}

-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')

-- Lazy Git
  local Terminal  = require('toggleterm.terminal').Terminal
  local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction="float" })

  function _lazygit_toggle()
    lazygit:toggle()
  end

  vim.api.nvim_set_keymap('n', '<leader>g', [[<cmd>lua _lazygit_toggle()<CR>]], { noremap = true, silent = true })

EOF
