"Header                                                                    {{{
"=============================================================================
"Last Change: 29 Aug 2013
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
"Script settings                                                           {{{
"=============================================================================
let s:save_cpo = &cpo   " allow line continuation
set cpo&vim

"==========================================================================}}}
"Globals + Dev Variable                                                    {{{
" The Top Level Function that determines program flow
"=============================================================================
if !exists("g:crunch_calc_prompt")
    let g:crunch_calc_prompt = 'Calc >> '
endif
if !exists("g:crunch_calc_comment")
    let g:crunch_calc_comment = '"'
endif

"=============================================================================
"crunch_debug enables varies echoes throughout the code
"=============================================================================
let s:debug = 0

"==========================================================================}}}
" s:PrintDebugHeader()                                                     {{{
"=============================================================================
function! s:PrintDebugHeader(text)
    if s:debug 
        echom repeat(' ', 80)
        echom repeat('=', 80)
        echom a:text . " Debug"
        echom repeat('-', 80)
    endif
endfunction

"==========================================================================}}}
" s:PrintDebugMsg()                                                        {{{
"=============================================================================
function! s:PrintDebugMsg(text)
    if s:debug 
        echom a:text
    endif
endfunction

"==========================================================================}}}
"crunch#Crunch                                                             {{{
" The Top Level Function that determines program flow
"=============================================================================
function! crunch#Crunch(input) 
    if a:input != ''
        let OriginalExpression = a:input
    else
        let OriginalExpression = s:GetInputString()
    endif
    if s:ValidLine(OriginalExpression) == 0 | return | endif
    let expression = s:RemoveOldResult(OriginalExpression)
    let expression = s:Core(expression)
    let result = s:EvaluateExpression(expression)
    " redraw
    echo expression
    echo "= " . result
    echo "Yanked Result"
    let @" = result
endfunction

"==========================================================================}}}
"crunch#CrunchLine                                                         {{{
" The Top Level Function that determines program flow
"=============================================================================
function! crunch#CrunchLine(line) 
    let OriginalExpression = getline(a:line)
    if s:ValidLine(OriginalExpression) == 0 | return | endif
    let OriginalExpression = s:RemoveOldResult(OriginalExpression)
    let expression = s:ReplaceTag(OriginalExpression)
    call s:PrintDebugMsg('['.OriginalExpression.'] is the OriginalExpression')
    let expression = s:Core(expression)
    let resultStr = s:EvaluateExpression(expression)
    call setline(a:line, OriginalExpression.' = '.resultStr)
    call s:PrintDebugMsg('['. resultStr . '] is the result' )
    return resultStr
endfunction

"==========================================================================}}}
"crunch#CrunchBlock                                                        {{{
" The Top Level Function that determines program flow
"=============================================================================
function! crunch#CrunchBlock() range
    let top = a:firstline
    let bot = a:lastline
    call s:PrintDebugMsg("range: " . top . ", " . bot) 
    if top == bot
        " when no range is given (or a sigle line, as it is not possible to
        " detect the difference), use the set of lines separed by blank lines
        let emptyLinePat = '\v^\s*$'
        while top > 1 && getline(top-1) !~ emptyLinePat
            let top -= 1
        endwhile
        while bot < line('$') && getline(bot+1) !~ emptyLinePat
            let bot += 1
        endwhile
        call s:PrintDebugMsg("new range: " . top . ", " . bot) 
    endif
    for line in range(top, bot)
        call crunch#CrunchLine(line)
    endfor
endfunction

"==========================================================================}}}
"s:Core                                                                    {{{
"the main functionality of crunch
"=============================================================================
function! s:Core(e) 
    let expression = a:e

    " convert ints to floats
    let expression = substitute(expression, 
                \ '\v(\d*\.=\d+)', '\=str2float(submatch(0))' , 'g')
    call s:PrintDebugMsg('[' . expression . 
                \'] = is the expression converted to floats')
    " convert implicit multiplication to explicit
    let expression = s:FixMultiplication(expression)

    return expression
endfunction

"==========================================================================}}}
"s:ValidLine                                                               {{{
"Checks the line to see if it is a variable definition, or a blank line that
"may or may not contain whitespace. 

"If the line is invalid this function returns false
"=============================================================================
function! s:ValidLine(expression) 
    call s:PrintDebugHeader('Valid Line')
    call s:PrintDebugMsg('[' . a:expression . '] = the tested string' )

    "checks for commented lines
    if a:expression =~ '\v^\s*' . g:crunch_calc_comment 
        return 0 
    endif
    " checks for empty/blank lines
    if a:expression =~ '\v^\s*$'
        return 0 
    endif 

    " checks for lines that don't need evaluation
    if a:expression =~ '\v\C^\s*var\s+\a+\s*\=\s*[0-9.]+$'
        return 0 
    endif 

    call s:PrintDebugMsg('It is a valid line!')
    return 1
endfunction


"==========================================================================}}}
"s:ReplaceTag                                                              {{{
"Replaces the tag within an expression with the value of that tag
"inspired by Ihar Filipau's inline calculator
"=============================================================================
function! s:ReplaceTag(expression) 
    call s:PrintDebugHeader('Replace Tag')

    let e = a:expression
    call s:PrintDebugMsg("[" . e . "] = expression before tag replacement " )

    " strip the variable marker, if any
    let e = substitute( e, '\v\C^\s*var\s+\a+\s*\=\s*', "", "" )
    call s:PrintDebugMsg("[" . e . "] = expression striped of tag") 

    " replace values by the tag
    let e = substitute( e, '\v(\a+)\ze([^(a-zA-z]|$)', 
                \ '\=s:GetTagValue(submatch(1))', 'g' )

    call s:PrintDebugMsg("[" . e . "] = expression after tag replacement ") 
    return e
endfunction

"==========================================================================}}}
"s:GetTagValue                                                             {{{
"Searches for the value of a tag and returns the value assigned to the tag
"inspired by Ihar Filipau's inline calculator
"=============================================================================
function! s:GetTagValue(tag)
    call s:PrintDebugHeader('Get Tag Value')

    call s:PrintDebugMsg("[" . a:tag . "] = the tag") 
    let s = search('\v\C^\s*var\s+\V' . a:tag . '\v\s*\=\s*' , "bn")
    call s:PrintDebugMsg("[" . s . "] = result of search for tag") 
    if s == 0 
        throw "Calc error: tag ".a:tag." not found" 
    endif
    " avoid substitute() as we are called from inside substitute()
    let line = getline(s)
    call s:PrintDebugMsg("[" . line . "] = line with tag value") 

    "TODO reevaluate tag expression here 

    call s:PrintDebugMsg("[" . line . "] = line with tag value after") 
    let idx = strridx( line, "=" )
    if idx == -1 
        throw "Calc error: line with tag ".a:tag." doesn't contain the '='" 
    endif
    let tagvalue= strpart( line, idx+1 )
    call s:PrintDebugMsg("[" . tagvalue . "] = the tag value") 
    return tagvalue
endfunction


"==========================================================================}}}
"s:RemoveOldResult                                                         {{{
"Remove old result if any eg '5+5 = 10' becomes '5+5'
"inspired by Ihar Filipau's inline calculator
"=============================================================================
function! s:RemoveOldResult(expression)
    call s:PrintDebugHeader('Remove Old Result')

    let e = a:expression
    "if it's a variable with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
    call s:PrintDebugMsg('[' . e . ']= expression before removed result')

    let e = substitute(e, '\v\s+$', "", "")
    call s:PrintDebugMsg('[' . e . ']= expression after removed trailing space')

    let e = substitute(e, '\v\s*\=\s*[-0-9e.]*\s*$', "", "")
    call s:PrintDebugMsg('[' . e . ']= expression after removed old result')

    return e
endfunction

"==========================================================================}}}
" s:GetInputString                                                         {{{
" prompt the user for an expression
"=============================================================================
function! s:GetInputString()
    call inputsave()
    let Expression = input(g:crunch_calc_prompt)
    call inputrestore()
    return Expression
endfunction

"==========================================================================}}}
" s:HandleCarrot                                                           {{{
" changes '2^5' into 'pow(2,5)' 
" cases
" fun()^fun() eg sin(1)^sin(1)
" fun()^num() eg sin(1)^2
" num^fun() eg 2^sin(1) 
" num^num() eg 2^2
" NOTE: this is not implemented and is a work in progress/failure
"=============================================================================
function! s:HandleCarrot(expression)
    let s:e = substitute(a:expression,'\([0-9.]\+\)\^\([0-9.]\+\)', 
                \ 'pow(\1,\2)','g') " good
    let s:e = substitute(s:e, '\(\a\+(.\{-})\)\^\([0-9.]\+\)', 
                \ 'pow(\1,\2)','g') "questionable 
    let s:e = substitute(s:e, '\([0-9.]\+\)\^\(\a\+(.\{-})\)', 
                \ 'pow(\1,\2)','g') "good 
    let s:e = substitute(s:e, '\(\a\+(.\{-})\)\^\(\a\+(.\{-})\)',
                \ 'pow(\1,\2)','g') "bad
    return s:e
endfunction

"==========================================================================}}}
" s:FixMultiplication                                                      {{{
" turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'
"=============================================================================
function! s:FixMultiplication(expression)
    call s:PrintDebugHeader('Fix Multiplication')

    "deal with ')( -> )*(', ')5 -> )*5' and 'sin(1)sin(1)'
    let e = substitute(a:expression,'\v(\))\s*([([:alnum:]])', '\1\*\2','g')
    call s:PrintDebugMsg('[' . e . ']= fixed multiplication 1') 

    "deal with '5sin( -> 5*sin(' and '5( -> 5*('
    let e = substitute(e,'\v([0-9.]+)\s*([([:alpha:]])', '\1\*\2','g')
    call s:PrintDebugMsg('[' . e . ']= fixed multiplication 3') 

    return e
endfunction

"==========================================================================}}}
" s:EvaluateExpression                                                     {{{
" Evaluates the expression and checks for errors in the process. Also 
" if there is no error echo the result and save a copy of it to the default 
" paste register
"=============================================================================
function! s:EvaluateExpression(expression)
    call s:PrintDebugHeader('Evaluate Expression')

    call s:PrintDebugMsg(" this is the final expression") 
    let errorFlag = 0
    " try
    let result = string(eval(a:expression))
    call s:PrintDebugMsg('['.matchstr(result,"\\.0$").'] is the matched string')
    if result =~ '\v\.0$'  "matches the 10 in 8e10 for some reason 
        "TODO? add in printf for large nums that would eval to e numbers
        let result = string(str2nr(result))
    endif

    " catch /^Vim\%((\a\+)\)\=:E/	" catch all Vim errors
    " let errorFlag = 1
    " endtry
    " if errorFlag == 1
    " let result = "ERROR: invalid input"
    " echom "ERROR: invalid input"
    " let @" = "ERROR: invalid input"
    " else
    "endif
    return result
endfunction

"==========================================================================}}}
"Restore settings                                                          {{{
"=============================================================================
let &cpo = s:save_cpo
" vim:set foldmethod=marker:
