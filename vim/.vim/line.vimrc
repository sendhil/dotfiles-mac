" Status Bar
set laststatus=2
let g:airline_powerline_fonts=1
set t_Co=256
let g:airline_theme='murmur'
let g:airline#extensions#tabline#enabled = 1
let g:airline_section_y=""
let g:airline_skip_empty_sections = 1
let g:airline_exclude_preview = 1
" let g:airline#extensions#tagbar#flags = 'f'

" function! VimGoAirline(...)
"   if &filetype == 'go'
"     let w:airline_section_warning = airline#section#create(['whitespace', '%{go#statusline#Show()}'])
"   endif
" endfunction
" call airline#add_statusline_func('VimGoAirline')
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

let g:airline_section_error = '%{airline#util#wrap(airline#extensions#coc#get_error(),0)}'
let g:airline_section_warning = '%{airline#util#wrap(airline#extensions#coc#get_warning(),0)}'

" Coc.Nvim
let g:airline#extensions#coc#enabled = 1
" let airline#extensions#coc#error_symbol = 'E:'
" let airline#extensions#coc#warning_symbol = 'W:'
let airline#extensions#coc#stl_format_err = '%E{[%e(#%fe)]}'
let airline#extensions#coc#stl_format_warn = '%W{[%w(#%fw)]}'

function! SetTabs()
  set autoindent noexpandtab tabstop=4 shiftwidth=4
endfunction
