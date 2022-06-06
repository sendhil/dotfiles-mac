" Status Bar
set laststatus=2
set t_Co=256

let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename', 'modified', 'statusline' ] ]
      \ },
      \ 'component_function': {
      \   'statusline': 'nvim_treesitter#statusline'
      \ },
      \ 'enable' : {
      \     'statusline': 1,
      \     'tabline': 0,
      \ },
      \ }
