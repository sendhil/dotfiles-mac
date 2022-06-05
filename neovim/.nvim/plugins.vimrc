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
EOF

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
