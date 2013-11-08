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
command! -nargs=? CrunchBlock call crunch#CrunchBlock(<q-args>)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"CrunchLine mapping
"Allows for users to define their own mappings. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchCrunchLine')
    map <unique> <leader>cl <Plug>CrunchCrunchLine
endif

noremap <unique> <script> <Plug>CrunchCrunchLine <SID>CrunchLine
noremap <SID>CrunchLine :CrunchLine<CR>

noremap <unique> <script> <Plug>CrunchCrunchLineExc <SID>CrunchLineExc
noremap <SID>CrunchLineExc :CrunchLine -exclusive<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"CrunchBlock mapping
"Allows for users to define their own mappings. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchCrunchBlock')
    map <unique> <leader>cb <Plug>CrunchCrunchBlock
endif

noremap <unique> <script> <Plug>CrunchCrunchBlock <SID>CrunchBlock
noremap <SID>CrunchBlock :CrunchBlock<CR>

noremap <unique> <script> <Plug>CrunchCrunchBlockExc <SID>CrunchBlockExc
noremap <SID>CrunchBlockExc :CrunchBlock -exclusive<CR>

" vim:foldmethod=marker
