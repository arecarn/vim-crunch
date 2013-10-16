"HEADER                                                                    {{{
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


let s:validVariable = '\v[a-zA-Z_]+[a-zA-Z0-9_]*'
let s:ErrorTag = 'Crunch error: '
let s:isExclusive = 0

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
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"MAIN FUNCTIONS                                                            {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"crunch#Crunch()                                                          {{{2
"When called opens a command window prompt for an equation to be evaluated
"Optionally can take input as a argument before opening a prompt 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Crunch(input)
    if a:input != ''
        let origExpr = a:input
    else
        let origExpr = s:GetInputString()
    endif

    try
        if s:ValidLine(origExpr) == 0 | return | endif
        let expr = s:FixMultiplication(origExpr)
        let expr = s:IntegerToFloat(expr)
        let result = s:EvaluateExpression(expr)

        echo expr
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
"crunch#CaptureArgs()                                                     {{{2
" Captures the range for later use, Handles arguments, and then calls 
" CrunchLine
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#CaptureArgs(args) range
    call s:PrintDebugMsg(a:args. 'is the Argument(s)')
    if a:args !=# ''
        call s:HandleArgs(a:args)
        let s:firstline = a:firstline
        let s:lastline = a:lastline
    endif
        execute a:firstline.','.a:lastline.'call crunch#CrunchLine()'
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#CrunchLine()                                                      {{{2
" evaluates a line in a buffer, allowing for prefixes and suffixes
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#CrunchLine()
    let origExpr = s:CrunchInit()
    try
        if s:ValidLine(origExpr) == 0 | return | endif
        let origExpr = s:RemoveOldResult(origExpr)
        let expr = s:ReplaceVariable(origExpr)
        let expr = s:FixMultiplication(expr)
        let expr = s:IntegerToFloat(expr)
        let resultStr = s:EvaluateExpression(expr)
    catch /Crunch error: /
        echohl ErrorMsg 
        echomsg v:exception
        echohl None
        let resultStr = v:exception
    endtry

    call setline('.', s:prefix.origExpr.' = '.resultStr.s:suffix)
    call s:PrintDebugMsg('['. resultStr.'] is the result' )
    return resultStr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#CrunchBlock()                                                     {{{2
"Evaluates a paragraph, equivalent to vip<leader>cl
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#CrunchBlock(args)
    call s:PrintDebugHeader('Crunch Block Debug')
    execute "normal! vip\<ESC>"
    let topline = line("'<")
    let bottomline = line("'>")

    call s:PrintDebugMsg('['.a:args.'] is the variable' )
    execute topline."," bottomline."call "."crunch#CaptureArgs(a:args)"
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" crunch#EvalTypes()                                                      {{{2
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
        throw s:ErrorTag ."'". a:EvalSource."'". 'is an invalid evaluation '.
                    \ 'source, Defaulting to VimScript'
        let s:crunch_using_vimscript = 1
    endif

endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"HELPER FUNCTIONS                                                          {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"s:HandleArgs()                                                           {{{2
"Interpret arguments to set flags accordingly
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:HandleArgs(args)
    call s:PrintDebugHeader('Handle Arguments Debug')
    call s:PrintDebugMsg('['.a:args.']= the arguments')
    if a:args ==# '-exclusive' || a:args ==# '-exc'
        call s:PrintDebugMsg('Exclusive set')
        let s:isExclusive = 1
    else 
    endif
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:CrunchInit()                                                           {{{2
" Gets the expression from current line, builds the suffix/prefix regex if
" need , and  removes the suffix and prefix from the expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:CrunchInit()
    call s:PrintDebugHeader('Crunch Inizilation Debug')

    let expr = getline('.')

    if !exists('b:filetype') || &filetype !=# b:filetype
        let b:filetype = &filetype
        call s:PrintDebugMsg('filetype set, rebuilding prefix/suffix regex')
        call s:PrintDebugMsg('['.&filetype.']= filetype')
        call s:BuildLinePrefix()
        call s:BuildLineSuffix()
    endif 

    let s:suffix = matchstr(expr, b:suffixRegex)
    let s:prefix = matchstr(expr, b:prefixRegex)
    let expr = s:RemovePrefixNSuffix(expr)

    return expr
endfunction
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:ValidLine()                                                            {{{2
"Checks the line to see if it is a variable definition, or a blank line that
"may or may not contain whitespace.

"If the line is invalid this function returns false
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ValidLine(expr)
    call s:PrintDebugHeader('Valid Line')
    call s:PrintDebugMsg('[' . a:expr . ']= the tested string' )

    "checks for commented lines
    if a:expr =~ '\v^\s*'.g:crunch_calc_comment
        call s:PrintDebugMsg('test1 failed')
        return 0
    endif

    " checks for empty/blank lines
    if a:expr =~ '\v^\s*$'
        call s:PrintDebugMsg('test2 failed')
        return 0
    endif

    " checks for lines that don't need evaluation
    if a:expr =~ '\v\C^\s*'.s:validVariable.'\s*\=\s*-?\s*[0-9.]+\s*$'
        call s:PrintDebugMsg('test3 failed')
        return 0
    endif
    call s:PrintDebugMsg('It is a valid line!')
    return 1
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:RemoveOldResult()                                                      {{{2
"Remove old result if any
"eg '5+5 = 10' becomes '5+5'
"eg 'var1 = 5+5 =10' becomes 'var1 = 5+5'
"inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RemoveOldResult(expr)
    call s:PrintDebugHeader('Remove Old Result')

    let expr = a:expr
    "if it's a variable with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
    call s:PrintDebugMsg('[' . expr . ']= expression before removed result')

    let expr = substitute(expr, '\v\s+$', "", "")
    call s:PrintDebugMsg('[' . expr . ']= after removed trailing space')

    let expr = substitute(expr, '\v\s*\=\s*[-0-9e.+]*\s*$', "", "")
    call s:PrintDebugMsg('[' . expr . ']= after removed old result')

    let expr = substitute(expr, '\v\s*\=\s*Crunch error:.*\s*$', "", "")
    call s:PrintDebugMsg('[' . expr . ']= after removed old error')

    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:ReplaceVariable()                                                      {{{2
"Replaces the variable within an expression with the value of that variable
"inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ReplaceVariable(expr)
    call s:PrintDebugHeader('Replace Variable')

    let expr = a:expr
    call s:PrintDebugMsg("[".expr."]= expression before variable replacement ")

    " strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "")
    call s:PrintDebugMsg("[".expr."]= expression striped of variable")

    " replace variable with it's value
    let expr = substitute( expr, '\v('.s:validVariable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:GetVariableValue(submatch(1))', 'g' )

    call s:PrintDebugMsg("[".expr."]= expression after variable replacement")
    let s:isExclusive = 0
    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:GetVariableValue()                                                     {{{2
"Searches for the value of a variable and returns the value assigned to the
"variable inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetVariableValue(variable)

    call s:PrintDebugHeader('Get Variable Value')
    call s:PrintDebugMsg("[".getline('.')."]= the current line")

    call s:PrintDebugMsg("[" . a:variable . "]= the variable")

    if s:isExclusive == 1
        call s:PrintDebugMsg("Searching with Stopline")
        call s:PrintDebugMsg("[".s:firstline."]= Stopline")
        let sline =search('\v\C^('.b:prefixRegex.
                    \ ')?\V'.a:variable.'\v\s*\=\s*', "bnW", (s:firstline -1))
    else
        let sline = search('\v\C^('.b:prefixRegex.
                    \ ')?\V'.a:variable.'\v\s*\=\s*' , "bnW")
    endif

    call s:PrintDebugMsg("[".sline."]= result of search for variable")
    if sline == 0
        throw s:ErrorTag."variable ".a:variable." not found"
    endif

    call s:PrintDebugMsg("[" .getline(sline). "]= line with variable value")
    let line = s:RemovePrefixNSuffix(getline(sline))
    call s:PrintDebugHeader('Get Variable Value Contiuned')

    let variableValue = matchstr(line,'\v\=\s*\zs-?\s*(\d*\.?\d+)\ze\s*$')
    call s:PrintDebugMsg("[" . variableValue . "]= the variable value")
    if variableValue == ''
        throw s:ErrorTag.'value for '.a:variable.' not found.'
    endif

    return '('.variableValue.')'
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:FixMultiplication()                                                   {{{2
" turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:FixMultiplication(expr)
    call s:PrintDebugHeader('Fix Multiplication')

    "deal with ')( -> )*(', ')5 -> )*5' and 'sin(1)sin(1)'
    let expr = substitute(a:expr,'\v(\))\s*([([:alnum:]])', '\1\*\2','g')
    call s:PrintDebugMsg('[' . expr . ']= fixed multiplication 1')

    "deal with '5sin( -> 5*sin(', '5( -> 5*( ', and  '5x -> 5*x'
    let expr = substitute(expr,'\v([0-9.]+)\s*([([:alpha:]])', '\1\*\2','g')
    call s:PrintDebugMsg('[' . expr . ']= fixed multiplication 2')

    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:IntegerToFloat()                                                      {{{2
" Convert Integers in the exprs to floats by calling a substitute
" command 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:IntegerToFloat(expr)
    let expr = a:expr

    "convert Ints to floats
    if s:crunch_using_vimscript
        call s:PrintDebugHeader('Integer To Floats')
        let expr = substitute(expr,
                    \ '\v(\d*\.=\d+)', '\=s:ConvertInt2Float(submatch(0))', 'g')
    endif

    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:ConvertInt2Float()                                                    {{{2
" Called by the substitute command in s:IntegerToFloat() convert integers to
" floats, and checks for digits that are too large for Vim script to evaluate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ConvertInt2Float(number)
    let num = a:number
    call s:PrintDebugMsg('['.num.']= number before converted to floats')

    if num =~ '\v^\d{8,}$'
        throw s:ErrorTag . num .' is too large for VimScript evaluation'
    endif

    let result = str2float(num)
    call s:PrintDebugMsg('['.string(result).']= number converted to floats 1')
    return  result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:RemovePrefixNSuffix()                                                  {{{2
"Removes the prefix and suffix from a string
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RemovePrefixNSuffix(expr)
    let expr = a:expr
    call s:PrintDebugHeader('Remove Line Prefix and Suffix')

    call s:PrintDebugMsg('['.b:prefixRegex.']= the REGEX of the prefix/suffix')
    call s:PrintDebugMsg('['.b:suffixRegex.']= the REGEX of the suffix/suffix')
    call s:PrintDebugMsg('['.expr.']= expression BEFORE removing prefix/suffix')
    let expr = substitute(expr, b:prefixRegex, '', '')
    call s:PrintDebugMsg('['.expr.']= expression AFTER removing prefix')
    let expr = substitute(expr, b:suffixRegex, '', '')
    call s:PrintDebugMsg('['.expr.']= expression AFTER removing suffix')
    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:BuildLineSuffix()                                                      {{{2
"from a list of suffixes builds a regex expression for all suffixes in the
"list
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildLineSuffix()
    call s:PrintDebugHeader('Build Line Suffix')
    call s:PrintDebugMsg( "[".&commentstring."]=  the comment string ")
    let s:commentEnd = matchstr(&commentstring, '\v.+\%s\zs.*')

    "Build the suffix

    "Valid Line suffix list
    let s:Linesuffixs = ["*","//", s:commentEnd]
    let b:suffixRegex = ''
    let NumberOfsuffixes = len(s:Linesuffixs)

    for suffix in s:Linesuffixs
        " call s:PrintDebugMsg( "[".suffix."]= suffix to be added to regex")
        let b:suffixRegex = b:suffixRegex.escape(suffix,'\/')
        if NumberOfsuffixes !=1
            let b:suffixRegex = b:suffixRegex.'\|'
        endif

        call s:PrintDebugMsg( "[".b:suffixRegex."]= REGEX for all the suffixes")
        let NumberOfsuffixes -= 1
    endfor
    let b:suffixRegex= '\V\s\*\('.b:suffixRegex.'\)\=\s\*\$\v'

    "NOTE: this regex is very non magic see :h \V
    call s:PrintDebugMsg("[".b:suffixRegex."]= REGEX for all the suffixes")
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:BuildLinePrefix()                                                      {{{2
"from a list of prefixes builds a regex expression for all prefixes in the
"list
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildLinePrefix()

    call s:PrintDebugHeader('Build Line Prefix')
    call s:PrintDebugMsg( "[".&commentstring."]=  the comment string ")
    let s:commentStart = matchstr(&commentstring, '\v.+\ze\%s')

    "Build the prefix

    "Valid Line Prefix list
    let s:LinePrefixs = ["*","//", s:commentStart]
    let b:prefixRegex = ''
    let NumberOfPrefixes = len(s:LinePrefixs)

    for prefix in s:LinePrefixs
        " call s:PrintDebugMsg( "[".prefix."]= prefix to be added to regex")
        let b:prefixRegex = b:prefixRegex.escape(prefix,'\/')
        if NumberOfPrefixes !=1
            let b:prefixRegex = b:prefixRegex.'\|'
        endif

        call s:PrintDebugMsg( "[".b:prefixRegex."]= REGEX for the prefixes")
        let NumberOfPrefixes -= 1
    endfor
    let b:prefixRegex= '\V\^\s\*\('.b:prefixRegex.'\)\=\s\*\v'

    "NOTE: this regex is very non magic see :h \V
    call s:PrintDebugMsg("[".b:prefixRegex."]= REGEX for all the prefixes")
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:GetInputString()                                                      {{{2
" prompt the user for an expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetInputString()
    call inputsave()
    let expr = input(g:crunch_calc_prompt)
    call inputrestore()
    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:EvaluateExpression()                                                  {{{2
" Evaluates the expression and checks for errors in the process. Also
" if there is no error echo the result and save a copy of it to the default
" paste register
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:EvaluateExpression(expr)
    call s:PrintDebugHeader('Evaluate Expression')
    call s:PrintDebugMsg('[' . a:expr . "]= the final expression")

    if s:crunch_using_octave == 1
        let result = s:OctaveEval(a:expr)
    elseif s:crunch_using_vimscript == 1
        let result = string(eval(a:expr))
    else
        let s:crunch_using_vimscript
        let result = string(eval(a:expr))
    endif

    call s:PrintDebugMsg('['.result.']= before trailing ".0" removed')
    call s:PrintDebugMsg('['.matchstr(result,'\v\.0+$').']= trailing ".0"')
    "check for trailing '.0' in result and remove it (occurs with vim eval)
    if result =~ '\v\.0+$'
        let result = string(str2nr(result))
    endif

    call s:PrintDebugMsg('['.result.']= before trailing "0" removed')
    call s:PrintDebugMsg('['.matchstr(result,'\v\.\d{-1,}\zs0+$').
                \ ']= trailing "0"')
    "check for trailing '0' in result ex .250 -> .25 (occurs with octave "eval)
    let result = substitute( result, '\v\.\d{-1,}\zs0+$', '', 'g')

    return result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:OctaveEval()                                                          {{{2
" Evaluates and expression using a systems Octave installation
" removes 'ans =' and trailing newline
" Errors in octave evaluation are thrown
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:OctaveEval(expr)
    let expr = a:expr

    let result = system('octave --quiet --norc', expr)

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
" vim:foldmethod=marker
