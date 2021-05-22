" Vim-Plug
"
call plug#begin('~/.vim/plugged') 

if has("nvim") 
  " Install nightly build, replace ./install.sh with install.cmd on windows
  Plug 'neoclide/coc.nvim', {'do': './install.sh nightly'}
endif

Plug 'vim-airline/vim-airline' 
Plug 'vim-airline/vim-airline-themes'
Plug 'https://github.com/altercation/vim-colors-solarized.git'
Plug 'tomtom/tcomment_vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tpope/vim-fugitive'
Plug 'fatih/vim-go'
Plug 'moll/vim-node'
Plug 'mtth/scratch.vim'
Plug 'kana/vim-smartinput'
Plug 'tpope/vim-surround'
Plug 'majutsushi/tagbar'
Plug 'scrooloose/nerdtree'
Plug 'easymotion/vim-easymotion'
Plug 'justinmk/vim-sneak'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
" Forked fzf.vim as I wanted to add a few options. At some submit back.
Plug 'sendhil/fzf.vim'
Plug 'rakr/vim-one'
Plug 'ryanoasis/vim-devicons'
Plug 'Shougo/denite.nvim'
Plug 'Shougo/neomru.vim'
" Plug 'ap/vim-css-color'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'airblade/vim-gitgutter'
Plug 'Yggdroot/indentLine'
Plug 'sebdah/vim-delve'
Plug 'vim-ctrlspace/vim-ctrlspace'
Plug 'sheerun/vim-polyglot'


call plug#end()

command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>), 1, <bang>0)

"TODO: Figure out variables to reduce this duplication
if has("win32") 
  source $HOME/vimfiles/general.vimrc
  source $HOME/vimfiles/plugins.vimrc
  source $HOME/vimfiles/line.vimrc
  source $HOME/vimfiles/keys.vimrc
else
  source $HOME/.vim/general.vimrc
  source $HOME/.vim/plugins.vimrc
  source $HOME/.vim/line.vimrc
  source $HOME/.vim/keys.vimrc
endif
