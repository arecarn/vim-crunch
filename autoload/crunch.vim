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
let s:prefixRegex = {}
let s:suffixRegex = {}

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
"When called opens a command window prompt for an equation to be evaluated
"Optionally can take input as a argument before opening a prompt 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Crunch(input)
    if a:input != ''
        let origExpression = a:input
    else
        let origExpression = s:GetInputString()
    endif

    try
        if s:ValidLine(origExpression) == 0 | return | endif
        let expression = s:FixMultiplication(origExpression)
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
" evaluates a line in a buffer, allowing for prefixes and suffixes
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#CrunchLine(line)
    let origExpression = s:RemovePrefixNSuffix(a:line, 'save')

    try
        if s:ValidLine(origExpression) == 0 | return | endif
        let origExpression = s:RemoveOldResult(origExpression)
        let expression = s:FixMultiplication(origExpression)
        let expression = s:ReplaceVariable(expression)
        let expression = s:IntegerToFloat(expression)
        let resultStr = s:EvaluateExpression(expression)
    catch /Crunch error: /
        echohl ErrorMsg 
        echomsg v:exception
        echohl None
        let resultStr = v:exception
    endtry

    call setline(a:line, s:prefix.origExpression.' = '.resultStr.s:suffix)
    call s:PrintDebugMsg('['. resultStr.'] is the result' )
    return resultStr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"=========================================================================}}}2
"crunch#CrunchBlock                                                       {{{2
"Evaluates a paragraph, equivalent to vip<leader>cl
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
" determines if the provided evaluation source is valid and activates the
" corresponding evaluation method
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Helper Functions                                                          {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" s:ConvertInt2Float()                                                    {{{2
" Called by the substitute command in s:IntegerToFloat() convert integers to
" floats, and checks for digits that are too large for Vim script to evaluate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ConvertInt2Float(number)
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
" Convert Integers in the expressions to floats by calling a substitute
" command 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:IntegerToFloat(expression)
    let expression = a:expression

    "convert Ints to floats
    if s:crunch_using_vimscript
        call s:PrintDebugHeader('Integer To Floats')
        let expression = substitute(expression,
                    \ '\v(\d*\.=\d+)', '\=s:ConvertInt2Float(submatch(0))', 'g')
    endif

    return expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:ValidLine                                                              {{{2
"Checks the line to see if it is a variable definition, or a blank line that
"may or may not contain whitespace.

"If the line is invalid this function returns false
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ValidLine(expression)
    call s:PrintDebugHeader('Valid Line')
    call s:PrintDebugMsg('[' . a:expression . '] = the tested string' )

    "checks for commented lines
    if a:expression =~ '\v^\s*'.g:crunch_calc_comment
        call s:PrintDebugMsg('test1 failed')
        return 0
    endif

    " checks for empty/blank lines
    if a:expression =~ '\v^\s*$'
        call s:PrintDebugMsg('test2 failed')
        return 0
    endif

    " checks for lines that don't need evaluation
    if a:expression =~ '\v\C^\s*'.s:validVariable.'\s*\=\s*[0-9.]+\s*$'
        call s:PrintDebugMsg('test3 failed')
        return 0
    endif
    call s:PrintDebugMsg('It is a valid line!')
    return 1
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:ReplaceVariable                                                        {{{2
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

    " replace variable with it's value
    let expression = substitute( expression, '\v('.s:validVariable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:GetVariableValue(submatch(1))', 'g' )

    call s:PrintDebugMsg("[" . expression . "] = expression after variable replacement ")
    return expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:GetVariableValue                                                       {{{2
"Searches for the value of a variable and returns the value assigned to the
"variable inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetVariableValue(variable)

    call s:PrintDebugHeader('Get Variable Value')
    call s:PrintDebugMsg("[".getline('.')."] = the current line")

    call s:PrintDebugMsg("[" . a:variable . "] = the variable")


    let s = search('\v\C^('.s:prefixRegex[s:ft].
                \ ')?\V'.a:variable.'\v\s*\=\s*' , "bnW")
    call s:PrintDebugMsg("[".s."] = result of search for variable")
    if s == 0
        throw s:ErrorTag."variable ".a:variable." not found"
    endif

    call s:PrintDebugMsg("[" .getline(s). "] = line with variable value after")
    let line = s:RemovePrefixNSuffix(s)
    call s:PrintDebugHeader('Get Variable Value Contiuned')

    let variableValue = matchstr(line,'\v\=\s*\zs(\d*\.?\d+)\ze\s*$')
    call s:PrintDebugMsg("[" . variableValue . "] = the variable value")
    if variableValue == ''
        throw s:ErrorTag.'value for '.a:variable.' not found.'
    endif

    return variableValue
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:BuildLineSuffix()                                                      {{{2
"from a list of suffixes builds a regex expression for all suffixes in the
"list
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildLineSuffix()
    if has_key(s:suffixRegex, s:ft)
        return
    endif
    call s:PrintDebugHeader('Build Line Suffix')
    let s:commentEnd = matchstr(&commentstring, '\v.+\%s\zs.*')

    "Build the suffix

    "Valid Line suffix list
    let s:Linesuffixs = ["*","//", s:commentEnd]
    let suffixRegex = ''
    let NumberOfsuffixes = len(s:Linesuffixs)

    for suffix in s:Linesuffixs
        " call s:PrintDebugMsg( "[".suffix."] = the suffix to be added to regex")
        let suffixRegex = suffixRegex.escape(suffix,'\/')
        if NumberOfsuffixes !=1
            let suffixRegex = suffixRegex.'\|'
        endif

        call s:PrintDebugMsg( "[".suffixRegex."] = the REGEX for all the suffixes")
        let NumberOfsuffixes -= 1
    endfor
    let suffixRegex= '\V\s\*\('.suffixRegex.'\)\=\s\*\$\v'

    "NOTE: this regex is very non magic see :h \V
    call s:PrintDebugMsg("[".suffixRegex."] = the REGEX for all the suffixes")

    let s:suffixRegex[s:ft] = suffixRegex
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:BuildLinePrefix()                                                      {{{2
"from a list of prefixes builds a regex expression for all prefixes in the
"list
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildLinePrefix()
    if has_key(s:prefixRegex, s:ft)
        return
    endif

    call s:PrintDebugHeader('Build Line Prefix')
    let s:commentStart = matchstr(&commentstring, '\v.+\ze\%s')

    "Build the prefix

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
    let prefixRegex= '\V\^\s\*\('.prefixRegex.'\)\=\s\*\v'

    "NOTE: this regex is very non magic see :h \V
    call s:PrintDebugMsg("[".prefixRegex."] = the REGEX for all the prefixes")

    let s:prefixRegex[s:ft] = prefixRegex
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:RemovePrefixNSuffix()                                                  {{{2
"Removes the prefix and suffix from a string
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RemovePrefixNSuffix(line, ...)
    call s:PrintDebugHeader('Remove Line Prefix and Suffix')
    let expression = getline(a:line)
    if a:0 == 1 && a:1 ==# 'save'
        let s:ft = '_'.&ft
        call s:BuildLinePrefix()
        call s:BuildLineSuffix()

        let s:suffix = matchstr(expression, s:suffixRegex[s:ft])
        let s:prefix = matchstr(expression, s:prefixRegex[s:ft])
    endif

    call s:PrintDebugMsg('['.s:prefixRegex[s:ft].']= the REGEX of the prefix and suffix')
    call s:PrintDebugMsg('['.s:suffixRegex[s:ft].']= the REGEX of the suffix and suffix')
    call s:PrintDebugMsg('['.expression.']= expr BEFORE removing prefix and suffix')
    let expression = substitute(expression, s:prefixRegex[s:ft], '', '')
    call s:PrintDebugMsg('['.expression.']= expr AFTER removing prefix')
    let expression = substitute(expression, s:suffixRegex[s:ft], '', '')
    call s:PrintDebugMsg('['.expression.']= expr AFTER removing suffix')
    return expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:RemoveOldResult                                                        {{{2
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
" s:GetInputString                                                        {{{2
" prompt the user for an expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetInputString()
    call inputsave()
    let Expression = input(g:crunch_calc_prompt)
    call inputrestore()
    return Expression
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:FixMultiplication                                                     {{{2
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
" s:EvaluateExpression                                                    {{{2
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
" s:OctaveEval                                                            {{{2
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

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}
" vim:set foldmethod=marker:
