"=============================================================================
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
"Globals                                                                   {{{
"=============================================================================
if !exists("g:crunch_calc_prompt")
    let g:crunch_calc_prompt = 'Calc >> '
endif
if !exists("g:crunch_calc_comment")
    let g:crunch_calc_comment = '"'
endif

if !exists("s:crunch_using_octave")
    let s:crunch_using_octave = 0
endif
if !exists("s:crunch_using_vimscript")
    let s:crunch_using_vimscript = 1
endif


"Valid Variable Regex
let s:validVariable = '\v[a-zA-Z_]+[0-9]*'

"==========================================================================}}}
"DEBUG                                                                     {{{
"crunch_debug enables varies echoes throughout the code
"=============================================================================
let s:debug = 0

"=============================================================================
" s:PrintDebugHeader()                                                    {{{2
"=============================================================================
function! s:PrintDebugHeader(text)
    if s:debug 
        echom repeat(' ', 80)
        echom repeat('=', 80)
        echom a:text." Debug"
        echom repeat('-', 80)
    endif
endfunction

"=========================================================================}}}2
" s:PrintDebugMsg()                                                       {{{2
"=============================================================================
function! s:PrintDebugMsg(text)
    if s:debug 
        echom a:text
    endif
endfunction

"=========================================================================}}}2

"==========================================================================}}}
"MAIN                                                                      {{{
"=============================================================================
"crunch#Crunch                                                            {{{2
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

    echo expression
    echo "= ".result
    echo "Yanked Result"
    "yank the result into the correct register
    if &cb == 'unnamed'
        let @* = result
    elseif &cb == 'unnamedplus'
        let @+ = result
    else
        let @" = result
    endif
endfunction

"=========================================================================}}}2
"crunch#CrunchLine                                                        {{{2
" The Top Level Function that determines program flow
"=============================================================================
function! crunch#CrunchLine(line) 
    let OriginalExpression = getline(a:line)
    if s:ValidLine(OriginalExpression) == 0 | return | endif
    let OriginalExpression = s:RemoveOldResult(OriginalExpression)
    call s:PrintDebugMsg('['.OriginalExpression.'] is the OriginalExpression')
    let expression = s:Core(OriginalExpression)
    let expression = s:ReplaceVariable(expression)
    let resultStr = s:EvaluateExpression(expression)
    call setline(a:line, OriginalExpression.' = '.resultStr)
    call s:PrintDebugMsg('['. resultStr.'] is the result' )
    return resultStr
endfunction

"=========================================================================}}}2
"crunch#CrunchBlock                                                       {{{2
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

"=========================================================================}}}2

"==========================================================================}}}
"s:Int2Float                                                               {{{
"Convert Integers to floats
"=============================================================================
function! s:Int2Float(number)
    let num = a:number
    call s:PrintDebugMsg('['.num.'] = number before converted to floats')

    if num =~ '\v^\d{8,}$' 
        throw 'Calc error:' . num .' is too large for VimScript evaluation'
    endif

    let result = str2float(num)
    call s:PrintDebugMsg('['.string(result).'] = number converted to floats 1')
    return  result
endfunction

"==========================================================================}}}
"s:Core                                                                    {{{
"the main functionality of crunch
"=============================================================================
function! s:Core(e) 
    let expression = a:e

    "convert Ints to floats
    if s:crunch_using_vimscript
        call s:PrintDebugHeader('Integer To Floats')
        let expression = substitute(expression, 
                    \ '\v(\d*\.=\d+)', '\=s:Int2Float(submatch(0))' , 'g')
    endif
    " convert implied multiplication to explicit multipication
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

    "TODO change variable
    " checks for lines that don't need evaluation
    if a:expression =~ '\v\C^\s*'.s:validVariable.'\s*\=\s*[0-9.]+$'
        return 0 
    endif 

    call s:PrintDebugMsg('It is a valid line!')
    return 1
endfunction


"==========================================================================}}}
"s:ReplaceVariable                                                         {{{
"Replaces the variable within an expression with the value of that variable
"inspired by Ihar Filipau's inline calculator
"=============================================================================
function! s:ReplaceVariable(expression) 
    call s:PrintDebugHeader('Replace Variable')

    let e = a:expression
    call s:PrintDebugMsg("[" . e . "] = expression before variable replacement " )

    "TODO change var
    " strip the variable marker, if any
    let e = substitute( e, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "" )
    call s:PrintDebugMsg("[" . e . "] = expression striped of variable") 

    "TODO change var
    let e = substitute( e, '\v('.s:validVariable.')\ze([^(a-zA-z]|$)', 
                \ '\=s:GetVariableValue(submatch(1))', 'g' )

    call s:PrintDebugMsg("[" . e . "] = expression after variable replacement ") 
    return e
endfunction

"==========================================================================}}}
"s:GetVariableValue                                                        {{{
"Searches for the value of a variable and returns the value assigned to the 
"variable inspired by Ihar Filipau's inline calculator
"=============================================================================
function! s:GetVariableValue(variable)

    call s:PrintDebugHeader('Get Variable Value')

    call s:PrintDebugMsg("[" . a:variable . "] = the variable") 

    
    let s = search('\v\C^\s*\V' . a:variable . '\v\s*\=\s*' , "bnW")
    call s:PrintDebugMsg("[" . s . "] = result of search for variable") 
    if s == 0 
        throw "Calc error: variable ".a:variable." not found" 
    endif

    " avoid substitute() as we are called from inside substitute()
    let line = getline(s)
    call s:PrintDebugMsg("[" . line . "] = line with variable value after") 
    let idx = strridx( line, "=" )
    if idx == -1 
        throw "Calc error: line with variable ".a:variable." doesn't contain the '='" 
    endif
    let variableValue = strpart( line, idx+1 )
    call s:PrintDebugMsg("[" . variableValue . "] = the variable value") 
    return variableValue
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

    "deal with '5sin( -> 5*sin(', '5( -> 5*( ', and  '5x -> 5*x'
    let e = substitute(e,'\v([0-9.]+)\s*([([:alpha:]])', '\1\*\2','g')
    call s:PrintDebugMsg('[' . e . ']= fixed multiplication 2') 

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
    call s:PrintDebugMsg('[' . a:expression . "]= the final expression") 

    if s:crunch_using_octave == 1
        let result = s:OctaveEval(a:expression)
    elseif s:crunch_using_vimscript == 1
        let result = string(eval(a:expression))
    else
        let s:crunch_using_vimscript
        let result = string(eval(a:expression))
    endif

    call s:PrintDebugMsg('['.result.']= before trailing ".0" removed')
    call s:PrintDebugMsg('['.matchstr(result,'\v\.0+$').']= trailing ".0"')
    "check for trailing '.0' in result and remove it (occurs with vim eval)
    if result =~ '\v\.0+$'  
        let result = string(str2nr(result))
    endif

    call s:PrintDebugMsg('['.result.']= before trailing "0" removed')
    call s:PrintDebugMsg('['.matchstr(result,'\v\.\d{-1,}\zs0+$').']= trailing "0"')
    "check for trailing '0' in result ex .250 -> .25 (occurs with octave "eval)
    let result = substitute( result, '\v\.\d{-1,}\zs0+$', '', 'g')

    return result
endfunction

"==========================================================================}}}
" s:OctaveEval                                                             {{{
" Evaluates and expression using a systems Octave installation
" removes 'ans =' and trailing newline
" Errors in octave evaluation are thrown 
"=============================================================================
function! s:OctaveEval(expression)
    let expression = a:expression

    let result = system('octave --quiet --norc', expression)

    let result = substitute(result, "\s*\n$", '' , 'g')
    call s:PrintDebugMsg('['.result.']= expression after newline removed')

    try
        if matchstr(result, '^error:') != ''
            throw "Calc ".result 
        endif
    endtry

    let result = substitute(result, 'ans =\s*', '' , 'g')
    call s:PrintDebugMsg('['.result.']= expression after ans removed')

    return result
endfunction

"==========================================================================}}}
" crunch#EvalTypes "                                                       {{{
" returns the possible evaluation types for Crunch 
"=============================================================================
function! crunch#EvalTypes(ArgLead, CmdLine, CursorPos)
    let s:evalTypes = [ 'Octave',  'VimScript' ]
    return s:evalTypes
endfunction

"==========================================================================}}}
" crunch#ChooseEval()                                                      {{{
" returns the possible evaluation types for Crunch 
"=============================================================================
function! crunch#ChooseEval(EvalSource)

    let s:crunch_using_octave = 0
    let s:crunch_using_vimscript = 0

    if a:EvalSource == 'VimScript'
        let s:crunch_using_vimscript = 1
    elseif a:EvalSource == 'Octave' 
        if s:OctaveEval('1+1')  == 2
            let s:crunch_using_octave = 1
        else 
            let s:crunch_using_vimscript = 1
            throw 'Calc error: Octave not avaiable'
        endif 
    else
        throw 'Crunch error: "'. a:EvalSource.'" is an invalid evaluation"
                    \ "source, Defaulting to VimScript"
        let s:crunch_using_vimscript = 1
    endif

endfunction

"==========================================================================}}}
"Restore settings                                                          {{{
"=============================================================================
let &cpo = s:save_cpo
" vim:set foldmethod=marker:
