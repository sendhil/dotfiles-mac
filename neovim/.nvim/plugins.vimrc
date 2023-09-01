" Treesitter Config
lua << EOF
  require'nvim-treesitter.configs'.setup {
    ensure_installed = { "c", "lua", "rust", "go", "python" },
    highlight = {
      enable = true,              -- false will disable the whole extension
      additional_vim_regex_highlighting = false,
    },
    rainbow = {
      enable = true,
      -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
      extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
      max_file_lines = nil, -- Do not enable for files with more than n lines, int
      -- colors = {}, -- table of hex strings
      -- termcolors = {} -- table of colour name strings
    }
  }

  require("indent_blankline").setup {
    char = "|",
    buftype_exclude = {"terminal"}
  }

  require'treesitter-context'.setup{
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
  }

  require("bufferline").setup{
    options = {
      mode = "tabs",
      diagnostics = "nvim_lsp",
      separator_style = "slant",
      offsets = {{filetype = "NvimTree", text = "File Explorer"}},
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local s = " "
        for e, n in pairs(diagnostics_dict) do
          local sym = e == "error" and " "
            or (e == "warning" and " " or "" )
          s = s .. n .. sym
        end
        return s
      end,
    }
  }

  require("toggleterm").setup{
    open_mapping = [[<c-\>]],
    shade_terminals = false,
  }

  function _G.set_terminal_keymaps()
    local opts = {noremap = true}
    vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
  end

  -- if you only want these mappings for toggle term use term://*toggleterm#* instead
  vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

  require("which-key").setup {
  }

  require('fidget').setup{}

  require('lsp_signature').setup(cfg)

  require('todo-comments').setup{}

  require('telescope').load_extension('file_browser')
  require('telescope').load_extension('fzf')
  require('telescope').load_extension('ui-select')

  vim.notify = require("notify")
EOF

let g:vista_default_executive = 'nvim_lsp'

source $HOME/.nvim/lsp.vimrc

let g:NERDTreeShowHidden=1
let g:NERDTreeQuitOnOpen = 1 

set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup
" Better display for messages
set cmdheight=2
" Smaller updatetime for CursorHold & CursorHoldI
set updatetime=300
" don't give |ins-completion-menu| messages.
set shortmess+=c
" always show signcolumns
set signcolumn=yes

" Hacks to fix the syntax coloring problem with vim-go. See https://github.com/fatih/vim-go/issues/145.
set nocursorcolumn

" Ctrl-Space
if executable("rg")
  let g:CtrlSpaceGlobCommand = 'rg --smart-case --hidden --follow --no-heading --files'
endif 
let g:CtrlSpaceUseTabline = 0
