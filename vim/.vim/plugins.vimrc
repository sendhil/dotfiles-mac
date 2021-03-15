" Deoplete
let g:deoplete#enable_at_startup = 1
if !exists('g:deoplete#omni#input_patterns')
  let g:deoplete#omni#input_patterns = {}
endif " let g:deoplete#disable_auto_complete = 1
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

let NERDTreeShowHidden=1

" Start coc.nvim config
" if hidden is not set, TextEdit might fail.
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


" The auto complete bits are from https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"

" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)
nmap <f2> <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)


" Add diagnostic info for https://github.com/itchyny/lightline.vim
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'cocstatus', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'cocstatus': 'coc#status'
      \ },
      \ }
" End coc.nvim config

" let g:easytags_async = 1
" let g:easytags_suppress_ctags_warning = 1

" GoLang
let g:go_fmt_command = "goimports"
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_gocode_unimported_packages = 1
let g:go_info_mode='gopls'
let g:go_def_mode='godef'
let g:ale_lint_on_text_changed = 'never'
let g:ale_sign_error = '⤫'
let g:ale_sign_warning = '⚠'

" Hacks to fix the syntax coloring problem with vim-go. See https://github.com/fatih/vim-go/issues/145.
set nocursorcolumn
"syntax sync minlines=256
" set re=1
"set synmaxcol=128
"

"FZF
set rtp+=/usr/local/opt/fzf

command! -bang -nargs=* GFiles call fzf#vim#gitfiles('', fzf#vim#with_preview('right'))
command! -bang -nargs=* GitFiles call fzf#vim#gitfiles('', fzf#vim#with_preview('right'))
let g:fzf_commands_insert_carriage_return = 1

" Ctrl-Space
if executable("rg")
  let g:CtrlSpaceGlobCommand = 'rg --smart-case --hidden --follow --no-heading --files'
endif 

" Neomake
" Look for local eslint and if not use globally installed one
let g:eslint_path = system('PATH=$(npm bin):$PATH && which eslint')
" let g:neomake_javascript_enabled_makers = ['eslint']
" let g:neomake_javascript_eslint_exe=substitute(g:eslint_path, '^\n*\s*\(.\{-}\)\n*\s*$', '\1', '')
" autocmd! BufWritePost * Neomake
"

let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'
" Use The Silver Searcher, if it's available
if executable('rg')
  let g:ctrlp_user_command = 'rg %s --files --color=never --glob ""'
  let g:ctrlp_use_caching = 0
  set grepprg=rg\ --vimgrep\ --no-heading\ --ignore-case
  set grepformat=%f:%l:%c:%m,%f:%l:%m
  let g:ackprg = 'rg --vimgrep --no-heading --ignore-case'
else
  " Refresh Ctrl-P when vim gains focus or a file is written
  if has("autocmd")
    augroup AuCtrlPCmd
      autocmd AuCtrlPCmd FocusGained * call s:CtrlPFlush()
      autocmd AuCtrlPCmd BufWritePost * call s:CtrlPFlush()
      function! s:CtrlPFlush(...)
        if exists(":ClearCtrlPCache") == 2
          ClearCtrlPCache
        endif
      endfunction
    augroup END
  endif
endif
