" Vim-Plug
"
call plug#begin('~/.nvim/plugged') 

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'liuchengxu/vista.vim'
Plug 'tpope/vim-surround'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'folke/trouble.nvim'
Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'kyazdani42/nvim-tree.lua'
Plug 'easymotion/vim-easymotion'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
Plug 'mhinz/vim-signify'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'vim-ctrlspace/vim-ctrlspace'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf'
Plug 'itchyny/lightline.vim'
Plug 'nvim-treesitter/playground'
Plug 'nvim-treesitter/nvim-treesitter-context'
Plug 'fatih/vim-go'
Plug 'akinsho/bufferline.nvim'
Plug 'akinsho/toggleterm.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'f-person/auto-dark-mode.nvim'
Plug 'folke/which-key.nvim'
Plug 'ggandor/lightspeed.nvim'


Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'jabirali/vim-tmux-yank'
Plug 'j-hui/fidget.nvim', { 'tag': 'legacy' }
Plug 'folke/twilight.nvim'
Plug 'folke/zen-mode.nvim'
Plug 'yamatsum/nvim-cursorline'
Plug 'RRethy/vim-illuminate'

"
" Themes
Plug 'rakr/vim-one'
Plug 'folke/tokyonight.nvim', { 'branch' : 'main' }
Plug 'shaunsingh/nord.nvim'
Plug 'navarasu/onedark.nvim'
Plug 'catppuccin/nvim'
Plug 'cpea2506/one_monokai.nvim'
Plug 'marko-cerovac/material.nvim'
Plug 'ray-x/lsp_signature.nvim'
Plug 'rcarriga/nvim-notify'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'tom-anders/telescope-vim-bookmarks.nvim'


" Untriaged

call plug#end()

" command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>), 1, <bang>0)

source $HOME/.nvim/general.vimrc
source $HOME/.nvim/plugins.vimrc
source $HOME/.nvim/keys.vimrc
source $HOME/.nvim/line.vimrc
