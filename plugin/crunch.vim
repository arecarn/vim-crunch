"=============================================================================
"Header                                                                    {{{
"=============================================================================
"Last Change: 25 Jul 2013
"Maintainer: Ryan Carney arecarn@gmail.com
"License:        DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
"                           Version 2, December 2004
"
"               Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
"
"      Everyone is permitted to copy and distribute verbatim or modified
"     copies of this license document, and changing it is allowed as long
"                           as the name is changed.
"
"                 DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
"       TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
"
"                   0. You just DO WHAT THE FUCK YOU WANT TO

"==========================================================================}}}

" Allows the user to disable the plugin
if exists("g:loaded_crunch")
    finish
endif
let g:loaded_crunch = 1

"==========================================================================}}}
" Commands                                                                 {{{
"=============================================================================

command! -nargs=* Crunch call crunch#Crunch('<args>')
command! -nargs=* -range CrunchLine <line1>,<line2>call crunch#CrunchLine()

"=============================================================================
"Crunch Line mapping
"Allows for users to define their own mappings. 
"=============================================================================
if !hasmapto('<Plug>CrunchCrunchLine')
    map <unique> <leader>cl  <Plug>CrunchCrunchLine
endif
noremap <unique> <script>   <Plug>CrunchCrunchLine  <SID>CrunchLine
noremap <SID>CrunchLine :CrunchLine<CR>

