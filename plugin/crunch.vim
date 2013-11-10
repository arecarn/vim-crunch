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

"COMMANDS{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=* Crunch call crunch#Crunch(<q-args>)
command! -nargs=? -range CrunchLine 
            \ <line1>,<line2>call crunch#Main(<q-args>)
command! -nargs=? CrunchBlock call crunch#EvalBlock(<q-args>)


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

" vim:foldmethod=marker
