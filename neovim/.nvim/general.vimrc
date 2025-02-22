set encoding=utf-8
runtime macros/matchit.vim 
set clipboard=unnamed

set ignorecase incsearch hlsearch number nocompatible
filetype plugin indent on
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set hidden
set ruler
set noshowmode

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

" Disable Python 2
let g:loaded_python_provider = 1

" These settings prevent vim from leaving swap files everywhere
if has("win32") 
  " store backup, undo, and swap files in temp directory
  set directory=$HOME/temp//
  set backupdir=$HOME/temp//
  set undodir=$HOME/temp//

  set backupdir+=%TEMP%
  set directory+=%TEMP%
  set undodir+=%TEMP%
else
  set backupdir=/tmp/
  set directory=/tmp
endif

if has("win32") 
  set backspace=2
  set backspace=indent,eol,start
endif

if has("unix") && !has("macunix")
  set clipboard=unnamedplus
endif

set guifont=Fura\ Code\ Nerd\ Font:h16
if has("gui_macvim")
  set guifont=Fira\ Code:h16
  set macligatures
endif

syntax enable

" if strftime('%H') < 19
"   set background=light
" else
"   set background=dark
" endif

" colorscheme catppuccin

colorscheme tokyonight
set background=dark

let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set termguicolors
set listchars=tab:▸\ ,eol:¬
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

" Formats JSON
com! FormatJSON %!python -m json.tool

" https://vimrcfu.com/snippet/143
command! Ctabs call s:Ctabs()
function! s:Ctabs()
  let files = {}
  for entry in getqflist()
    let filename = bufname(entry.bufnr)
    let files[filename] = 1
  endfor

  for file in keys(files)
    silent exe "tabedit ".file
  endfor
endfunction

lua << EOF

require 'nvim-tree'.setup {
  hijack_netrw = true,
}

local create_cmd = vim.api.nvim_create_user_command

create_cmd("ToggleBackground", function()
  if vim.o.background == 'dark' then
    vim.cmd'set bg=light'
  else
    vim.cmd'set bg=dark'
  end
end, {})

create_cmd("ToggleFloat", function()
  vim.cmd'ToggleTerm direction=float' 
end, {})
EOF
