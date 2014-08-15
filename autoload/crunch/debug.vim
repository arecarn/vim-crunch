"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" crunch#debug#PrintHeader()                                                 {{{ 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#debug#PrintHeader(text)
    if g:crunch_debug
        echom repeat(' ', 80)
        echom repeat('=', 80)
        echom a:text." Debug"
        echom repeat('-', 80)
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" crunch#debug#PrintMsg()                                                    {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#debug#PrintMsg(text)
    if g:crunch_debug
        echom a:text
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" crunch#debug#PrintVarMsg()                                                 {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#debug#PrintVarMsg(variable, text)
    if g:crunch_debug
        echom '['.a:variable.'] = '.a:text
    endif
endfunction
