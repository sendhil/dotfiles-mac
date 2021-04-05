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

" Useful for debugging slow syntax highlighting
" syntime on 

" set regexpengine=1
" set lazyredraw   " don't redraw everytime
" set synmaxcol=128  " avoid slow rendering for long lines
" syntax sync minlines=64  " faster syntax hl

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

" set guifont=Sauce\ Code\ Powerline:h14
" set guifont=Fira\ Code:h14
set guifont=Fura\ Code\ Nerd\ Font:h16
" set guifont=Source\ Code\ Pro:h14
if has("gui_macvim")
  " set guifont=Sauce\ Code\ Powerline\ Light:h16  
  set guifont=Fira\ Code:h16
  set macligatures
  " set guifont=Source\ Code\ Pro:h20
endif

" Solarized Theme Settings
" if !has('gui_running')
"   " This fixes an issue with tmux
"   let g:solarized_visibility = "high" 
" end

syntax enable
" let g:solarized_contrast = "high"
" let g:solarized_termtrans=1
" let g:solarized_termcolors = 256
" set background=dark
" colorscheme solarized

set background=dark
colorscheme one
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set termguicolors

autocmd FileType ruby set commentstring=#\ %s

" highlight OverLength ctermbg=darkred ctermfg=white guibg=#592929
" match OverLength /\%101v.\+/
"
" some new stuff
"
let g:indentLine_enabled = 0

set listchars=tab:▸\ ,eol:¬

command! -bang -nargs=* Find
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

" Likewise, Files command with preview window
command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

" Formats JSON
com! FormatJSON %!python -m json.tool
