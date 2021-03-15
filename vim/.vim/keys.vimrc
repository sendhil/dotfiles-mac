let mapleader=','
" map <C-h> <C-w>h map <C-j> <C-w>j
" map <C-k> <C-w>k
" map <C-l> <C-w>l
if has("win32")
    map <C-e> :MRU<CR>
else
    map <C-e> :History<CR>
  endif

" List Navigation
map <expr> <C-n> (empty(getloclist(1))  ? ":cn" : ":lnext")."\n"
map <expr> <C-p> (empty(getloclist(0))  ? ":cp" : ":lp")."\n"

" nmap <Leader>f :LAg<CR>
" nmap <Leader>F :LAg
nmap <Leader>f :Rg<CR>
nmap <Leader>F :Rg

" nnoremap <F6> "=strftime("%FT%T%z")<CR>P

cnoremap %% <C-R>=expand('%:h').'/'<cr>
map <leader>ew :e %%
map <leader>es :sp %%
map <leader>ev :vsp %%
map <leader>et :tabe %%

map <leader>ct :tabclose<CR>
map <leader>st :tab split<CR>

nmap <leader>. :CtrlPTag<CR>
let g:ctrlp_map = '<leader>t'
nmap <silent> <F5> :set spell!<CR>

nmap \e :NERDTreeToggle<CR>
nmap \t :TagbarToggle<CR>

" nmap <Leader>a= :Tabularize /=<CR>
" nmap <Leader>a{ :Tabularize /{<CR>
" nmap <Leader>a: :Tabularize /:\zs<CR>
" nmap <Leader>a> :Tabularize /=><CR>
xmap \\ :TComment<CR>
nmap \\ :TComment<CR>

nmap T :terminal<CR> :startinsert<CR>
nnoremap <leader>ov :exe ':silent !code %'<CR>:redraw!<CR>

nmap <Leader>p :Commands<CR>

" Unite
call denite#custom#map('insert', '<C-j>', '<denite:move_to_next_line>', 'noremap')
call denite#custom#map('insert', '<C-n>', '<denite:move_to_next_line>', 'noremap')
call denite#custom#map('insert', '<C-k>', '<denite:move_to_previous_line>', 'noremap')
call denite#custom#map('insert', '<C-p>', '<denite:move_to_previous_line>', 'noremap')

" neomake
" nmap <Leader><Space>o :lopen<CR>      " open location window
" nmap <Leader><Space>c :lclose<CR>     " close location window
" nmap <Leader><Space>, :ll<CR>         " go to current error/warning
" nmap <Leader><Space>n :lnext<CR>      " next error/warning
" nmap <Leader><Space>p :lprev<CR>      " previous error/warning

" coc.nvim
nnoremap <silent> K :call <SID>show_documentation()<CR>
nmap <leader>qf :CocAction quickfix<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Man Pages
au FileType man nmap gd :Man<CR>

" Go
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>bt <Plug>(go-test-compile)
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
au FileType go nmap <Leader>ga <Plug>(go-alternate-edit)
au Filetype go nmap <leader>gah <Plug>(go-alternate-split)
au Filetype go nmap <leader>gav <Plug>(go-alternate-vertical)
au FileType go nmap <Leader>i <Plug>(go-info)
au FileType go nmap <leader>c <Plug>(go-callers)
au FileType go nmap gr <Plug>(go-referrers)
au FileType go nmap <leader>d :GoDecls<CR>
au FileType go nmap <leader>D :GoDeclsDir<CR>

" Javascript
au FileType javascript nmap <leader>jd :JsDoc<CR>

" Python
au FileType python nnoremap <buffer> <F9> :exec '!python' shellescape(@%, 1)<cr>

" Ctrl-Space
let g:CtrlSpaceDefaultMappingKey = "<C-space> "
