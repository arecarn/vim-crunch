""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Maintainer: Ryan Carney
"Repository: https://github.com/arecarn/crunch
"License: WTFPL
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"GLOBALS & AUTOCMDS{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists("g:loaded_crunch")
    finish
else
    let g:loaded_crunch = 1
endif

let g:crunch_prompt = get(g:, 'crunch_prompt', 'Calc >> ')
let g:crunch_comment = get(g:, 'crunch_comment', '"')
let g:crunch_user_variables = get(g:, 'crunch_user_variables', {})
let g:crunch_result_type_append = get(g:, 'crunch_result_type_append', 1)
let g:util_debug = get(g:, 'util_debug', 0)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"COMMANDS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! -nargs=* -range=0 -bang Crunch
            \ call crunch#command(<count>, <line1>, <line2>, <q-args>, "<bang>")
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"OPERATOR {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <unique> <script> <Plug>(crunch-operator) <SID>crunch_operator
nnoremap <SID>crunch_operator :<C-U>set opfunc=crunch#operator<CR>g@
if !hasmapto('<Plug>crunch-operator')
    nmap <unique> g= <Plug>(crunch-operator)
endif

nnoremap <unique> <script> <Plug>(crunch-operator-line) <SID>crunch_operator_line
nnoremap <SID>crunch_operator_line :<C-U>set opfunc=crunch#operator<CR>g@_
nmap <unique> g== <Plug>(crunch-operator-line)

xnoremap <unique> <script> <Plug>(visual-crunch-operator) <SID>visual_crunch_operator
xnoremap <SID>visual_crunch_operator :<C-U>call crunch#operator(visualmode())<CR>
if !hasmapto('<Plug>visual-crunch-operator')
    xmap <unique> g= <Plug>(visual-crunch-operator)
endif
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" vim:foldmethod=marker
