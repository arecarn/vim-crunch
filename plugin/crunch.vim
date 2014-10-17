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
let g:crunch_debug = get(g:, 'crunch_debug', 0)
let g:crunch_user_variables = get(g:, 'crunch_user_variables', {})
let g:crunch_result_type_append = get(g:, 'crunch_result_type_append', 1)

augroup crunch_mode
    autocmd!
    autocmd CursorMoved * let g:crunch_mode = mode()
augroup END
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"COMMANDS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! -nargs=* -range=0 -bang Crunch
            \ call crunch#Command(<count>, <line1>, <line2>, <q-args>, "<bang>")
command! CrunchLine :echoerr "removed: use :[range]Crunch, g={movement}"
command! CrunchBlock :echoerr "removed: use vip:Crunch or g=ip"
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

"REMOVED MAPPINGS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchEvalLine')
    map <unique> <leader>cl <Plug>CrunchEvalLine
endif
noremap <unique> <script> <Plug>CrunchEvalLine <SID>CrunchLine
noremap <SID>CrunchLine :CrunchLine<CR>

if !hasmapto('<Plug>CrunchEvalBlock')
    map <unique> <leader>cb <Plug>CrunchEvalBlock
endif
noremap <unique> <script> <Plug>CrunchEvalBlock <SID>CrunchBlock
noremap <SID>CrunchBlock :CrunchBlock<CR>
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" vim:foldmethod=marker
