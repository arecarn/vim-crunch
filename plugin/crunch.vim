"HEADER{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Maintainer: Ryan Carney arecarn@gmail.com
"Repository: https://github.com/arecarn/crunch
"License: WTFPL

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}


" Allows the user to disable the plugin
if exists("g:loaded_crunch")
    finish
endif


let g:loaded_crunch = 1
let g:crunchMode = 'n'

augroup crunchMode
    autocmd!
    autocmd CursorMoved * let g:crunchMode = mode()
augroup END

"COMMANDS{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=* Crunch call crunch#Crunch(<q-args>)
" command! -nargs=? -range CrunchLine 
"             \ <line1>,<line2>call crunch#Main(<q-args>)
command! -nargs=* -range=0 -bang CrunchDev
            \ call crunch#Dev(<count>, <line1>, <line2>, <q-args>, "<bang>")
command! -nargs=* -range=0 -bang CrunchLine
            \ call crunch#Dev(<count>, <line1>, <line2>, <q-args>, "<bang>")
command! -nargs=? CrunchBlock call crunch#EvalPar(<q-args>)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"CrunchLine mapping
"Allows for users to define their own mappings. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchEvalLine')
    map <unique> <leader>cl <Plug>CrunchEvalLine
endif

noremap <unique> <script> <Plug>CrunchEvalLine <SID>CrunchLine
noremap <SID>CrunchLine :CrunchLine<CR>

noremap <unique> <script> <Plug>CrunchEvalLineExc <SID>CrunchLineExc
noremap <SID>CrunchLineExc :CrunchLine -exclusive<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"CrunchBlock mapping
"Allows for users to define their own mappings. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchEvalBlock')
    map <unique> <leader>cb <Plug>CrunchEvalBlock
endif

noremap <unique> <script> <Plug>CrunchEvalBlock <SID>CrunchBlock
noremap <SID>CrunchBlock :CrunchBlock<CR>

noremap <unique> <script> <Plug>CrunchEvalBlockExc <SID>CrunchBlockExc
noremap <SID>CrunchBlockExc :CrunchBlock -exclusive<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <unique> <script> <plug>CrunchOperator <SID>CrunchOperator
nnoremap <SID>CrunchOperator :<C-U>set opfunc=crunch#operator<CR>g@
if !hasmapto('<Plug>CrunchOperator')
    nmap <unique> g= <Plug>CrunchOperator
    nmap <unique> g== <Plug>CrunchOperator_
endif

xnoremap <unique> <script> <plug>VisualCrunchOperator  <SID>VisualCrunchOperator
xnoremap <SID>VisualCrunchOperator :<C-U>call crunch#operator(visualmode())<CR>
if !hasmapto('<Plug>VisualCrunchOperator')
    xmap <unique> g= <Plug>VisualCrunchOperator
endif

" vim:foldmethod=marker
