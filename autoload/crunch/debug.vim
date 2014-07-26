""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Maintainer: Ryan Carney
"Repository: https://github.com/arecarn/crunch
"License: WTFPL
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"DEBUG {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#debug#PrintHeader(text) "{{{2
    if g:crunch_debug
        echom repeat(' ', 80)
        echom repeat('=', 80)
        echom a:text." Debug"
        echom repeat('-', 80)
    endif
endfunction "}}}2

function! crunch#debug#PrintMsg(text) "{{{2
    if g:crunch_debug
        echom a:text
    endif
endfunction "}}}2

function! crunch#debug#PrintVarMsg(variable, text) "{{{2
    if g:crunch_debug
        echom '['.a:variable.'] = '.a:text
    endif
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

let &cpo = save_cpo
" vim:foldmethod=marker
