let  s:debug = 0

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" crunch#debug#PrintHeader()                                                 {{{ 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#debug#PrintHeader(text)
    if s:debug
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
    if s:debug
        echom a:text
    endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" debug#Enable()                                                            {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#debug#Enable(enable)
    if a:enable
        let  s:debug = 1
    else
        let  s:debug = 0
    endif
endfunction
