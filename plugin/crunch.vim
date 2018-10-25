""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Original Author: Ryan Carney
" License: WTFPL
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" BOILER PLATE {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_crunch')
    finish
else
    let g:loaded_crunch = 1
endif
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" GLOBALS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:crunch_prompt = get(g:, 'crunch_prompt', 'Calc >> ')
let g:crunch_comment = get(g:, 'crunch_comment', '"')
let g:crunch_user_variables = get(g:, 'crunch_user_variables', {})
let g:crunch_result_type_append = get(g:, 'crunch_result_type_append', 1)
let g:util_debug = get(g:, 'util_debug', 0)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" COMMANDS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! -nargs=* -range=0 -bang Crunch
            \ call crunch#command(<count>, <line1>, <line2>, <q-args>, "<bang>")
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" MAPPINGS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <silent> <script> <Plug>(crunch-operator)
            \ :<C-U>call crunch#normal_operator()<Bar>
            \ :set opfunc=crunch#operator<CR>g@
if !hasmapto('<Plug>(crunch-operator)')
    nmap <unique> g= <Plug>(crunch-operator)
endif

nnoremap <silent> <script> <Plug>(crunch-operator-line)
            \ :<C-U>call crunch#linewise_operator()<Bar>
            \ :set opfunc=crunch#operator<Bar>
            \ :execute 'normal!'.v:count1.'g@_'<CR>
if !hasmapto('<Plug>(crunch-operator-line)')
    nmap <unique> g== <Plug>(crunch-operator-line)
endif

xnoremap <silent> <script> <Plug>(visual-crunch-operator)
            \ :<C-U>call crunch#visual_operator()<Bar>
            \ :call crunch#operator(visualmode())<CR>
if !hasmapto('<Plug>(visual-crunch-operator)')
    xmap <unique> g= <Plug>(visual-crunch-operator)
endif
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" BOILER PLATE {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let &cpo = s:save_cpo
unlet s:save_cpo
" vim:foldmethod=marker
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
