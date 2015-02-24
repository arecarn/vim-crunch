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
            \ call crunch#Command(<count>, <line1>, <line2>, <q-args>, "<bang>")
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"OPERATOR {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <unique> <script> <plug>CrunchOperator <SID>CrunchOperator
nnoremap <SID>CrunchOperator :<C-U>set opfunc=crunch#Operator<CR>g@

if !hasmapto('<Plug>CrunchOperator')
    nmap <unique> g= <Plug>CrunchOperator
    nmap <unique> g== <Plug>CrunchOperator_
endif

xnoremap <unique> <script> <plug>VisualCrunchOperator  <SID>VisualCrunchOperator
xnoremap <SID>VisualCrunchOperator :<C-U>call crunch#Operator(visualmode())<CR>

if !hasmapto('<Plug>VisualCrunchOperator')
    xmap <unique> g= <Plug>VisualCrunchOperator
endif
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" vim:foldmethod=marker
