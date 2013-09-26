"Header                                                                    {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Last Change: 26 Sept 2013
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Script settings                                                          {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let save_cpo = &cpo   " allow line continuation
set cpo&vim

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" Globals                                                                  {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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
let s:validVariable = '\v[a-zA-Z_]+[a-zA-Z0-9_]*'
let s:ErrorTag = 'Crunch error: '

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"Debug Resources                                                           {{{
"crunch_debug enables varies echoes throughout the code
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:debug = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" s:PrintDebugHeader()                                                    {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:PrintDebugHeader(text)
    if s:debug
        echom repeat(' ', 80)
        echom repeat('=', 80)
        echom a:text." Debug"
        echom repeat('-', 80)
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:PrintDebugMsg()                                                       {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:PrintDebugMsg(text)
    if s:debug
        echom a:text
    endif
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Top Level Functions                                                       {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"crunch#Crunch                                                            {{{2
" The Top Level Function that determines program flow
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Crunch(input)
    if a:input != ''
        let OriginalExpression = a:input
    else
        let OriginalExpression = s:GetInputString()
    endif

    let s:prefixRegex = ''
    try
        if s:ValidLine(OriginalExpression) == 0 | return | endif
        let expression = s:FixMultiplication(OriginalExpression)
        let expression = s:IntegerToFloat(expression)
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
    catch /Crunch error: /
        echohl ErrorMsg 
        echomsg v:exception

        echohl None
    endtry
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#CrunchLine                                                        {{{2
" The Top Level Function that determines program flow
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#CrunchLine(line)
    let OriginalExpression = getline(a:line)

    call s:PrintDebugMsg('['.OriginalExpression.'] is the OriginalExpression')
    let s:prefixRegex = s:BuildLinePrefix()

    try
        "check if valid
        if s:ValidLine(OriginalExpression) == 0 | return | endif
        let OriginalExpression = s:RemoveOldResult(OriginalExpression)
        let expression = s:RemoveLinePrefix(OriginalExpression)
        let expression = s:FixMultiplication(expression)
        let expression = s:ReplaceVariable(expression)
        let expression = s:IntegerToFloat(expression)
        let resultStr = s:EvaluateExpression(expression)
    catch /Crunch error: /
        echohl ErrorMsg 
        echomsg v:exception
        echohl None
        let resultStr = v:exception
    endtry
    call setline(a:line, OriginalExpression.' = '.resultStr)
    call s:PrintDebugMsg('['. resultStr.'] is the result' )
    return resultStr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#CrunchBlock                                                       {{{2
" The Top Level Function that determines program flow
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" function! crunch#CrunchBlock() range
"     let top = a:firstline
"     let bot = a:lastline
"     call s:PrintDebugMsg("range: " . top . ", " . bot)
"     if top == bot
"         " when no range is given (or a sigle line, as it is not possible to
"         " detect the difference), use the set of lines separed by blank lines
"         let emptyLinePat = '\v^\s*$'
"         while top > 1 && getline(top-1) !~ emptyLinePat
"             let top -= 1
"         endwhile
"         while bot < line('$') && getline(bot+1) !~ emptyLinePat
"             let bot += 1
"         endwhile
"         call s:PrintDebugMsg("new range: " . top . ", " . bot)
"     endif
"     for line in range(top, bot)
"         call crunch#CrunchLine(line)
"     endfor
" endfunction

"=========================================================================}}}2
"s:CrunchBlock                                                            {{{2
"Temporary fix for issue #12: CrunchBlock command calculates using variables
"incorrectly depending on cursor position
"=============================================================================
function! crunch#CrunchBlock()
    execute "normal! vip\<ESC>"
    let topline = line("'<")
    let bottomline = line("'>")
    execute topline . "," bottomline . "call " . "crunch#CrunchLine('.')"
endfunction
 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" crunch#EvalTypes                                                        {{{2
" returns the possible evaluation types for Crunch
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#EvalTypes(ArgLead, CmdLine, CursorPos)
    let s:evalTypes = [ 'Octave',  'VimScript' ]
    return s:evalTypes
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" crunch#ChooseEval()                                                     {{{2
" returns the possible evaluation types for Crunch
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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
            throw s:ErrorTag . 'Octave not avaiable'
        endif
    else
        throw s:ErrorTag .'"'. a:EvalSource.'" is an invalid evaluation"
                    \ "source, Defaulting to VimScript"
        let s:crunch_using_vimscript = 1
    endif

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Helper Functions                                                          {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" s:Int2Float()                                                           {{{2
"Convert Integers to floats
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:Int2Float(number)
    let num = a:number
    call s:PrintDebugMsg('['.num.'] = number before converted to floats')

    if num =~ '\v^\d{8,}$'
        throw s:ErrorTag . num .' is too large for VimScript evaluation'
    endif

    let result = str2float(num)
    call s:PrintDebugMsg('['.string(result).'] = number converted to floats 1')
    return  result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:IntegerToFloat()                                                      {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:IntegerToFloat(expression)
    let expression = a:expression

    "convert Ints to floats
    if s:crunch_using_vimscript
        call s:PrintDebugHeader('Integer To Floats')
        let expression = substitute(expression,
                    \ '\v(\d*\.=\d+)', '\=s:Int2Float(submatch(0))' , 'g')
    endif

    return expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"ValidLine                                                                {{{2
"Checks the line to see if it is a variable definition, or a blank line that
"may or may not contain whitespace.

"If the line is invalid this function returns false
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ValidLine(expression)
    call s:PrintDebugHeader('Valid Line')
    call s:PrintDebugMsg('[' . a:expression . '] = the tested string' )

    "checks for commented lines
    if a:expression =~ '\v^'.s:prefixRegex.'\s*' . g:crunch_calc_comment
        call s:PrintDebugMsg('test1 failed')
        return 0
    endif

    " checks for empty/blank lines
    if a:expression =~ '\v^'.s:prefixRegex.'\s*$'
        call s:PrintDebugMsg('test2 failed')
        return 0
    endif

    " checks for lines that don't need evaluation
    if a:expression =~ '\v\C^'.s:prefixRegex.'\s*'.s:validVariable.'\s*\=\s*[0-9.]+\s*$'
        call s:PrintDebugMsg('test3 failed')
        return 0
    endif
    call s:PrintDebugMsg('It is a valid line!')
    return 1
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"ReplaceVariable                                                          {{{2
"Replaces the variable within an expression with the value of that variable
"inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ReplaceVariable(expression)
    call s:PrintDebugHeader('Replace Variable')

    let expression = a:expression
    call s:PrintDebugMsg("[".expression."] = expression before variable replacement " )

    " strip the variable marker, if any
    let expression = substitute( expression, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "" )
    call s:PrintDebugMsg("[".expression."] = expression striped of variable")

    let expression = substitute( expression, '\v('.s:validVariable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:GetVariableValue(submatch(1))', 'g' )

    call s:PrintDebugMsg("[" . expression . "] = expression after variable replacement ")
    return expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"GetVariableValue                                                         {{{2
"Searches for the value of a variable and returns the value assigned to the
"variable inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetVariableValue(variable)

    call s:PrintDebugHeader('Get Variable Value')
    call s:PrintDebugMsg("[".getline('.')."] = the current line")

    call s:PrintDebugMsg("[" . a:variable . "] = the variable")


    let s = search('\v\C^\s*('.s:prefixRegex.')=\s*\V'.a:variable.'\v\s*\=\s*' , "bnW")
    call s:PrintDebugMsg("[".s."] = result of search for variable")
    if s == 0
        throw s:ErrorTag."variable ".a:variable." not found"
    endif

    let line = getline(s)
    call s:PrintDebugMsg("[" . line . "] = line with variable value after")
    let line = s:RemoveLinePrefix(line)

    let variableValue = matchstr(line,'\v\=\s*\zs(\d*\.=\d+)\ze\s*$')
    call s:PrintDebugMsg("[" . variableValue . "] = the variable value")
    if variableValue == ''
        throw s:ErrorTag.'value for '.a:variable.' not found.'
    endif

    return variableValue
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:BuildLinePrefix()                                                      {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildLinePrefix()
    call s:PrintDebugHeader('Build Line Prefix')
    " let commentEnd = matchstr(&commentstring, '\v.+\%s\zs.+')
    let s:commentStart = matchstr(&commentstring, '\v.+\ze\%s')


    "Valid Line Prefix list
    let s:LinePrefixs = ["*","//", s:commentStart]
    let prefixRegex = ''
    let NumberOfPrefixes = len(s:LinePrefixs)

    for prefix in s:LinePrefixs
        " call s:PrintDebugMsg( "[".prefix."] = the prefix to be added to regex")
        let prefixRegex = prefixRegex.escape(prefix,'\/')
        if NumberOfPrefixes !=1
            let prefixRegex = prefixRegex.'\|'
        endif

        call s:PrintDebugMsg( "[".prefixRegex."] = the REGEX for all the prefixes")
        let NumberOfPrefixes -= 1
    endfor
    let prefixRegex= '\V\s\*\('.prefixRegex.'\)\=\s\*\v'

    "NOTE: this regex is very non magic see :h \V
    call s:PrintDebugMsg("[".prefixRegex."] = the REGEX for all the prefixes")

    return prefixRegex
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:RemoveLinePrefix()                                                     {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function!s:RemoveLinePrefix(e)
    call s:PrintDebugHeader('Remove Line Prefix')
    let expression = a:e

    call s:PrintDebugMsg('['.s:prefixRegex.']= the REGEX of the prefix')
    call s:PrintDebugMsg('['.expression.']= expr BEFORE removing prefix')
    let expression = substitute(expression, '^'.s:prefixRegex, '', '')
    call s:PrintDebugMsg('['.expression.']= expr AFTER removing prefix')
    return expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"RemoveOldResult                                                          {{{2
"Remove old result if any
"eg '5+5 = 10' becomes '5+5'
"eg 'var1 = 5+5 =10' becomes 'var1 = 5+5'
"inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RemoveOldResult(expression)
    call s:PrintDebugHeader('Remove Old Result')

    let expression = a:expression
    "if it's a variable with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
    call s:PrintDebugMsg('[' . expression . ']= expression before removed result')

    let expression = substitute(expression, '\v\s+$', "", "")
    call s:PrintDebugMsg('[' . expression . ']= after removed trailing space')

    let expression = substitute(expression, '\v\s*\=\s*[-0-9e.+]*\s*$', "", "")
    call s:PrintDebugMsg('[' . expression . ']= after removed old result')

    let expression = substitute(expression, '\v\s*\=\s*Crunch error:.*\s*$', "", "")
    call s:PrintDebugMsg('[' . expression . ']= after removed old error')

    return expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" GetInputString                                                          {{{2
" prompt the user for an expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetInputString()
    call inputsave()
    let Expression = input(g:crunch_calc_prompt)
    call inputrestore()
    return Expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" HandleCarrot                                                            {{{2
" changes '2^5' into 'pow(2,5)'
" cases
" fun()^fun() eg sin(1)^sin(1)
" fun()^num() eg sin(1)^2
" num^fun() eg 2^sin(1)
" num^num() eg 2^2
" NOTE: this is not implemented and is a work in progress/failure
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:HandleCarrot(expression)
    let s:expression = substitute(a:expression,'\([0-9.]\+\)\^\([0-9.]\+\)',
                \ 'pow(\1,\2)','g') " good
    let s:expression = substitute(s:expression, '\(\a\+(.\{-})\)\^\([0-9.]\+\)',
                \ 'pow(\1,\2)','g') "questionable
    let s:expression = substitute(s:expression, '\([0-9.]\+\)\^\(\a\+(.\{-})\)',
                \ 'pow(\1,\2)','g') "good
    let s:expression = substitute(s:expression, '\(\a\+(.\{-})\)\^\(\a\+(.\{-})\)',
                \ 'pow(\1,\2)','g') "bad
    return s:expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" FixMultiplication                                                       {{{2
" turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:FixMultiplication(expression)
    call s:PrintDebugHeader('Fix Multiplication')

    "deal with ')( -> )*(', ')5 -> )*5' and 'sin(1)sin(1)'
    let expression = substitute(a:expression,'\v(\))\s*([([:alnum:]])', '\1\*\2','g')
    call s:PrintDebugMsg('[' . expression . ']= fixed multiplication 1')

    "deal with '5sin( -> 5*sin(', '5( -> 5*( ', and  '5x -> 5*x'
    let expression = substitute(expression,'\v([0-9.]+)\s*([([:alpha:]])', '\1\*\2','g')
    call s:PrintDebugMsg('[' . expression . ']= fixed multiplication 2')

    return expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" EvaluateExpression                                                      {{{2
" Evaluates the expression and checks for errors in the process. Also
" if there is no error echo the result and save a copy of it to the default
" paste register
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" OctaveEval                                                              {{{2
" Evaluates and expression using a systems Octave installation
" removes 'ans =' and trailing newline
" Errors in octave evaluation are thrown
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:OctaveEval(expression)
    let expression = a:expression

    let result = system('octave --quiet --norc', expression)

    let result = substitute(result, "\s*\n$", '' , 'g')
    call s:PrintDebugMsg('['.result.']= expression after newline removed')

    try
        if matchstr(result, '^error:') != ''
            throw 'Crunch ' . result
        endif
    endtry

    let result = substitute(result, 'ans =\s*', '' , 'g')
    call s:PrintDebugMsg('['.result.']= expression after ans removed')

    return result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"Restore settings                                                         {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let &cpo = save_cpo


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" vim:set foldmethod=marker:
