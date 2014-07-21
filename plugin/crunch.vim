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
command! -nargs=* -range=0 -bang Crunch
            \ call crunch#Dev(<count>, <line1>, <line2>, <q-args>, "<bang>")

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
