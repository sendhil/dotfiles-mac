" Treesitter Config
lua << EOF
  require'nvim-treesitter.configs'.setup {
    ensure_installed = { "c", "lua", "rust", "go", "python" },
    highlight = {
      enable = true,              -- false will disable the whole extension
      additional_vim_regex_highlighting = false,
    },
  }

  require("indent_blankline").setup {
    char = "|",
    buftype_exclude = {"terminal"}
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
