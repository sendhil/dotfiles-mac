" Vim-Plug
"
call plug#begin('~/.vim/plugged') 

if has("nvim") 
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } " autocompletion framework
    Plug 'zchee/deoplete-go', { 'do': 'make'}
    Plug 'zchee/deoplete-jedi' " autocompletion source
    Plug 'w0rp/ale' " using flake8
endif

Plug 'ternjs/tern_for_vim', { 'do': 'npm install' }

Plug 'mileszs/ack.vim'
Plug 'rking/ag.vim' 
Plug 'vim-airline/vim-airline' 
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-bundler'
Plug 'jvirtanen/vim-cocoapods'
Plug 'https://github.com/altercation/vim-colors-solarized.git'
Plug 'tomtom/tcomment_vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'xolox/vim-easytags'
Plug 'tpope/vim-fugitive'
Plug 'fatih/vim-go'
Plug 'othree/html5.vim'
Plug 'claco/jasmine.vim'
Plug 'moll/vim-node'
Plug 'StanAngeloff/php.vim'
Plug 'tpope/vim-rails'
Plug 'hallison/vim-rdoc'
Plug 'mtth/scratch.vim'
Plug 'kana/vim-smartinput'
Plug 'tpope/vim-surround'
Plug 'keith/swift.vim'
Plug 'godlygeek/tabular'
Plug 'majutsushi/tagbar'
Plug 't-yuki/vim-go-coverlay'
Plug 'othree/javascript-libraries-syntax.vim'
Plug 'othree/jsdoc-syntax.vim'
Plug 'gavocanov/vim-js-indent'
Plug 'elzr/vim-json'
Plug 'mxw/vim-jsx'
Plug 'heavenshell/vim-jsdoc'
Plug 'othree/yajs.vim', { 'for': 'javascript' }
Plug 'xolox/vim-misc'
Plug 'itspriddle/vim-jquery'
Plug 'millermedeiros/vim-esformatter'
Plug 'scrooloose/nerdtree'
Plug 'sendhil/vim-snippets'
" Plug 'benekastah/neomake'
" Plug 'benjie/neomake-local-eslint.vim'
Plug 'easymotion/vim-easymotion'
Plug 'Shougo/neosnippet.vim'
Plug 'vim-syntastic/syntastic'
Plug 'sendhil/fzf.vim'
Plug 'rakr/vim-one'
Plug 'ryanoasis/vim-devicons'
Plug 'Shougo/denite.nvim'
Plug 'Shougo/neomru.vim'
Plug 'ap/vim-css-color'
Plug 'mattn/emmet-vim'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'airblade/vim-gitgutter'
Plug 'leafgarland/typescript-vim'
Plug 'ekalinin/Dockerfile.vim'
Plug 'saltstack/salt-vim'
Plug 'Yggdroot/indentLine'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }}
Plug 'sebdah/vim-delve'
Plug 'vim-ctrlspace/vim-ctrlspace'

" Typescript
Plug 'mhartington/nvim-typescript', {'do': './install.sh'}
Plug 'HerringtonDarkholme/yats.vim'

if has("win32") 
Plug 'vim-scripts/mru.vim'
endif

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
