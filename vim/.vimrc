" Vim-Plug
"
call plug#begin('~/.vim/plugged') 

if has("nvim") 
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } " autocompletion framework
    Plug 'zchee/deoplete-go', { 'do': 'make'}
    Plug 'zchee/deoplete-jedi' " autocompletion source
    Plug 'w0rp/ale' " using flake8
endif

Plug 'vim-airline/vim-airline' 
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-bundler'
Plug 'https://github.com/altercation/vim-colors-solarized.git'
Plug 'tomtom/tcomment_vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tpope/vim-fugitive'
Plug 'fatih/vim-go'
Plug 'moll/vim-node'
Plug 'tpope/vim-rails'
Plug 'mtth/scratch.vim'
Plug 'kana/vim-smartinput'
Plug 'tpope/vim-surround'
Plug 'godlygeek/tabular'
Plug 'majutsushi/tagbar'
Plug 'gavocanov/vim-js-indent'
Plug 'heavenshell/vim-jsdoc'
Plug 'othree/yajs.vim', { 'for': 'javascript' }
Plug 'xolox/vim-misc'
Plug 'millermedeiros/vim-esformatter'
Plug 'scrooloose/nerdtree'
Plug 'easymotion/vim-easymotion'
Plug 'justinmk/vim-sneak'
Plug 'Shougo/neosnippet.vim'
Plug 'vim-syntastic/syntastic'
Plug 'junegunn/fzf.vim'
Plug 'rakr/vim-one'
Plug 'ryanoasis/vim-devicons'
Plug 'Shougo/denite.nvim'
Plug 'Shougo/neomru.vim'
Plug 'ap/vim-css-color'
Plug 'mattn/emmet-vim'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'airblade/vim-gitgutter'
Plug 'leafgarland/typescript-vim'
Plug 'Yggdroot/indentLine'
Plug 'sebdah/vim-delve'
" Plug 'vim-ctrlspace/vim-ctrlspace'

" Typescript
Plug 'mhartington/nvim-typescript', {'do': './install.sh'}
Plug 'HerringtonDarkholme/yats.vim'

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
