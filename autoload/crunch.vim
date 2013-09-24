"Header                                                                    {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Last Change: 09 Sept 2013
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
let g:errMsg = ''

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"Debug Resources                                                           {{{
"crunch_debug enables varies echoes throughout the code
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:debug = 0

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PrintDebugHeader()                                                      {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! PrintDebugHeader(text)
    if s:debug
        echom repeat(' ', 80)
        echom repeat('=', 80)
        echom a:text." Debug"
        echom repeat('-', 80)
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" PrintDebugMsg()                                                         {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! PrintDebugMsg(text)
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
        let OriginalExpression = GetInputString()
    endif

    let s:prefixRegex = ''
    try
        if ValidLine(OriginalExpression) == 0 | return | endif
        let expression = FixMultiplication(OriginalExpression)
        let expression = IntegerToFloat(expression)
        let result = EvaluateExpression(expression)

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
    catch
        echohl ErrorMsg 
        echomsg g:errMsg

        echohl None
    endtry
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#CrunchLine                                                        {{{2
" The Top Level Function that determines program flow
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#CrunchLine(line)
    let OriginalExpression = getline(a:line)

    call PrintDebugMsg('['.OriginalExpression.'] is the OriginalExpression')
    let s:prefixRegex = BuildLinePrefix()

    try
        "check if valid
        if ValidLine(OriginalExpression) == 0 | return | endif
        let OriginalExpression = RemoveOldResult(OriginalExpression)
        let expression = RemoveLinePrefix(OriginalExpression)
        let expression = FixMultiplication(expression)
        let expression = ReplaceVariable(expression)
        let expression = IntegerToFloat(expression)
        let resultStr = EvaluateExpression(expression)
    catch
        echohl ErrorMsg 
        echomsg g:errMsg
        echohl None
        let resultStr = g:errMsg
    endtry
    call setline(a:line, OriginalExpression.' = '.resultStr)
    call PrintDebugMsg('['. resultStr.'] is the result' )
    return resultStr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#CrunchBlock                                                       {{{2
" The Top Level Function that determines program flow
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" function! crunch#CrunchBlock() range
"     let top = a:firstline
"     let bot = a:lastline
"     call PrintDebugMsg("range: " . top . ", " . bot)
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
"         call PrintDebugMsg("new range: " . top . ", " . bot)
"     endif
"     for line in range(top, bot)
"         call crunch#CrunchLine(line)
"     endfor
" endfunction

"==========================================================================}}}
"s:CrunchBlock                                                             {{{
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
        if OctaveEval('1+1')  == 2
            let s:crunch_using_octave = 1
        else
            let s:crunch_using_vimscript = 1
            let g:errMsg = 'Crunch error: Octave not avaiable'
            throw 'Crunch error: Octave not avaiable'
        endif
    else
        let g:errMsg = 'Crunch error: "'. a:EvalSource.'" is an invalid evaluation"
                    \ "source, Defaulting to VimScript"
        throw 'Crunch error: "'. a:EvalSource.'" is an invalid evaluation"
                    \ "source, Defaulting to VimScript"
        let s:crunch_using_vimscript = 1
    endif

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Int2Float()                                                              {{{
"Convert Integers to floats
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! Int2Float(number)
    let num = a:number
    call PrintDebugMsg('['.num.'] = number before converted to floats')

    if num =~ '\v^\d{8,}$'
        let g:errMsg = 'Crunch error:' . num .' is too large for VimScript evaluation'
        throw 'Crunch error:' . num .' is too large for VimScript evaluation'
    endif

    let result = str2float(num)
    call PrintDebugMsg('['.string(result).'] = number converted to floats 1')
    return  result
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" IntegerToFloat()                                                         {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! IntegerToFloat(expression)
    let expression = a:expression

    "convert Ints to floats
    if s:crunch_using_vimscript
        call PrintDebugHeader('Integer To Floats')
        let expression = substitute(expression,
                    \ '\v(\d*\.=\d+)', '\=Int2Float(submatch(0))' , 'g')
    endif

    return expression
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"ValidLine                                                                {{{
"Checks the line to see if it is a variable definition, or a blank line that
"may or may not contain whitespace.

"If the line is invalid this function returns false
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ValidLine(expression)
    call PrintDebugHeader('Valid Line')
    call PrintDebugMsg('[' . a:expression . '] = the tested string' )

    "checks for commented lines
    if a:expression =~ '\v^'.s:prefixRegex.'\s*' . g:crunch_calc_comment
        call PrintDebugMsg('test1 failed')
        return 0
    endif

    " checks for empty/blank lines
    if a:expression =~ '\v^'.s:prefixRegex.'\s*$'
        call PrintDebugMsg('test2 failed')
        return 0
    endif

    " checks for lines that don't need evaluation
    if a:expression =~ '\v\C^'.s:prefixRegex.'\s*'.s:validVariable.'\s*\=\s*[0-9.]+\s*$'
        call PrintDebugMsg('test3 failed')
        return 0
    endif
    call PrintDebugMsg('It is a valid line!')
    return 1
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"ReplaceVariable                                                           {{{
"Replaces the variable within an expression with the value of that variable
"inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ReplaceVariable(expression)
    call PrintDebugHeader('Replace Variable')

    let expression = a:expression
    call PrintDebugMsg("[".expression."] = expression before variable replacement " )

    " strip the variable marker, if any
    let expression = substitute( expression, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "" )
    call PrintDebugMsg("[".expression."] = expression striped of variable")

    let expression = substitute( expression, '\v('.s:validVariable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=GetVariableValue(submatch(1))', 'g' )

    call PrintDebugMsg("[" . expression . "] = expression after variable replacement ")
    return expression
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"GetVariableValue                                                          {{{
"Searches for the value of a variable and returns the value assigned to the
"variable inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! GetVariableValue(variable)

    call PrintDebugHeader('Get Variable Value')
    call PrintDebugMsg("[".getline('.')."] = the current line")

    call PrintDebugMsg("[" . a:variable . "] = the variable")


    let s = search('\v\C^\s*('.s:prefixRegex.')=\s*\V'.a:variable.'\v\s*\=\s*' , "bnW")
    call PrintDebugMsg("[".s."] = result of search for variable")
    if s == 0
        let g:errMsg = "Crunch error: variable ".a:variable." not found"
        throw "Crunch error: variable ".a:variable." not found"
    endif

    let line = getline(s)
    call PrintDebugMsg("[" . line . "] = line with variable value after")
    let line = RemoveLinePrefix(line)

    let variableValue = matchstr(line,'\v\=\s*\zs(\d*\.=\d+)\ze\s*$')
    call PrintDebugMsg("[" . variableValue . "] = the variable value")
    if variableValue == ''
        let g:errMsg = 'Crunch error: value for '.a:variable.' not found.'
        throw 'Crunch error: value for '.a:variable.' not found.'
    endif

    return variableValue
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"BuildLinePrefix()                                                         {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! BuildLinePrefix()
    call PrintDebugHeader('Build Line Prefix')
    " let commentEnd = matchstr(&commentstring, '\v.+\%s\zs.+')
    let s:commentStart = matchstr(&commentstring, '\v.+\ze\%s')


    "Valid Line Prefix list
    let s:LinePrefixs = ["*","//", s:commentStart]
    let prefixRegex = ''
    let NumberOfPrefixes = len(s:LinePrefixs)

    for prefix in s:LinePrefixs
        " call PrintDebugMsg( "[".prefix."] = the prefix to be added to regex")
        let prefixRegex = prefixRegex.escape(prefix,'\/')
        if NumberOfPrefixes !=1
            let prefixRegex = prefixRegex.'\|'
        endif

        call PrintDebugMsg( "[".prefixRegex."] = the REGEX for all the prefixes")
        let NumberOfPrefixes -= 1
    endfor
    let prefixRegex= '\V\s\*\('.prefixRegex.'\)\=\s\*\v'

    "NOTE: this regex is very non magic see :h \V
    call PrintDebugMsg("[".prefixRegex."] = the REGEX for all the prefixes")

    return prefixRegex
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"RemoveLinePrefix()                                                        {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function!RemoveLinePrefix(e)
    call PrintDebugHeader('Remove Line Prefix')
    let expression = a:e

    call PrintDebugMsg('['.s:prefixRegex.']= the REGEX of the prefix')
    call PrintDebugMsg('['.expression.']= expr BEFORE removing prefix')
    let expression = substitute(expression, '^'.s:prefixRegex, '', '')
    call PrintDebugMsg('['.expression.']= expr AFTER removing prefix')
    return expression
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"RemoveOldResult                                                           {{{
"Remove old result if any
"eg '5+5 = 10' becomes '5+5'
"eg 'var1 = 5+5 =10' becomes 'var1 = 5+5'
"inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RemoveOldResult(expression)
    call PrintDebugHeader('Remove Old Result')

    let expression = a:expression
    "if it's a variable with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
    call PrintDebugMsg('[' . expression . ']= expression before removed result')

    let expression = substitute(expression, '\v\s+$', "", "")
    call PrintDebugMsg('[' . expression . ']= after removed trailing space')

    let expression = substitute(expression, '\v\s*\=\s*[-0-9e.+]*\s*$', "", "")
    call PrintDebugMsg('[' . expression . ']= after removed old result')

    let expression = substitute(expression, '\v\s*\=\s*Crunch error:.*\s*$', "", "")
    call PrintDebugMsg('[' . expression . ']= after removed old error')

    return expression
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" GetInputString                                                           {{{
" prompt the user for an expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! GetInputString()
    call inputsave()
    let Expression = input(g:crunch_calc_prompt)
    call inputrestore()
    return Expression
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" HandleCarrot                                                             {{{
" changes '2^5' into 'pow(2,5)'
" cases
" fun()^fun() eg sin(1)^sin(1)
" fun()^num() eg sin(1)^2
" num^fun() eg 2^sin(1)
" num^num() eg 2^2
" NOTE: this is not implemented and is a work in progress/failure
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! HandleCarrot(expression)
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" FixMultiplication                                                        {{{
" turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! FixMultiplication(expression)
    call PrintDebugHeader('Fix Multiplication')

    "deal with ')( -> )*(', ')5 -> )*5' and 'sin(1)sin(1)'
    let expression = substitute(a:expression,'\v(\))\s*([([:alnum:]])', '\1\*\2','g')
    call PrintDebugMsg('[' . expression . ']= fixed multiplication 1')

    "deal with '5sin( -> 5*sin(', '5( -> 5*( ', and  '5x -> 5*x'
    let expression = substitute(expression,'\v([0-9.]+)\s*([([:alpha:]])', '\1\*\2','g')
    call PrintDebugMsg('[' . expression . ']= fixed multiplication 2')

    return expression
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" EvaluateExpression                                                       {{{
" Evaluates the expression and checks for errors in the process. Also
" if there is no error echo the result and save a copy of it to the default
" paste register
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! EvaluateExpression(expression)
    call PrintDebugHeader('Evaluate Expression')
    call PrintDebugMsg('[' . a:expression . "]= the final expression")

    if s:crunch_using_octave == 1
        let result = OctaveEval(a:expression)
    elseif s:crunch_using_vimscript == 1
        let result = string(eval(a:expression))
    else
        let s:crunch_using_vimscript
        let result = string(eval(a:expression))
    endif

    call PrintDebugMsg('['.result.']= before trailing ".0" removed')
    call PrintDebugMsg('['.matchstr(result,'\v\.0+$').']= trailing ".0"')
    "check for trailing '.0' in result and remove it (occurs with vim eval)
    if result =~ '\v\.0+$'
        let result = string(str2nr(result))
    endif

    call PrintDebugMsg('['.result.']= before trailing "0" removed')
    call PrintDebugMsg('['.matchstr(result,'\v\.\d{-1,}\zs0+$').']= trailing "0"')
    "check for trailing '0' in result ex .250 -> .25 (occurs with octave "eval)
    let result = substitute( result, '\v\.\d{-1,}\zs0+$', '', 'g')

    return result
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" OctaveEval                                                               {{{
" Evaluates and expression using a systems Octave installation
" removes 'ans =' and trailing newline
" Errors in octave evaluation are thrown
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! OctaveEval(expression)
    let expression = a:expression

    let result = system('octave --quiet --norc', expression)

    let result = substitute(result, "\s*\n$", '' , 'g')
    call PrintDebugMsg('['.result.']= expression after newline removed')

    try
        if matchstr(result, '^error:') != ''
            let g:errMsg = "Crunch ".result
            throw "Crunch ".result
        endif
    endtry

    let result = substitute(result, 'ans =\s*', '' , 'g')
    call PrintDebugMsg('['.result.']= expression after ans removed')

    return result
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"Restore settings                                                          {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let &cpo = save_cpo
" vim:set foldmethod=marker:
