""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"HEADER                                                                    {{{
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" COMMANDS                                                                 {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=* Crunch call crunch#Crunch('<args>')
command! -nargs=? -range CrunchLine 
            \ <line1>,<line2>call crunch#CaptureArgs('<args>')
command! -nargs=? CrunchBlock call crunch#CrunchBlock('<args>')


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"CrunchLine mapping
"Allows for users to define their own mappings. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchCrunchLine')
    map <unique> <leader>cl <Plug>CrunchCrunchLine
endif

noremap <unique> <script> <Plug>CrunchCrunchLine <SID>CrunchLine
noremap <SID>CrunchLine :CrunchLine<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"CrunchBlock mapping
"Allows for users to define their own mappings. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchCrunchBlock')
    map <unique> <leader>cb <Plug>CrunchCrunchBlock
endif

noremap <unique> <script> <Plug>CrunchCrunchBlock <SID>CrunchBlock
noremap <SID>CrunchBlock :CrunchBlock<CR>

" vim:foldmethod=marker
