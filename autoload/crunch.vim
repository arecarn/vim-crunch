"HEADER{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Maintainer: Ryan Carney arecarn@gmail.com
"Repository: https://github.com/arecarn/crunch
"License: WTFPL

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"SCRIPT SETTINGS                                                           {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let save_cpo = &cpo   " allow line continuation
set cpo&vim

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"GLOBALS                                                                   {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !exists("g:crunch_calc_prompt")
    let g:crunch_calc_prompt = 'Calc >> '
endif
if !exists("g:crunch_calc_comment")
    let g:crunch_calc_comment = '"'
endif

let s:capturedVariables = {} 
let s:numPat = '\v[-+]?%(\.\d+|\d+%([.]\d+)?%([eE][+-]?\d+)?)'
let s:validVariable = '\v[a-zA-Z_]+[a-zA-Z0-9_]*'
let s:ErrorTag = 'Crunch error: '
let s:isExclusive = 0

let g:crunch_debug = 0

" mutually exclusive
" defualt vim
let g:crunch_eval_type_python = 0
let g:crunch_eval_type_vim    = 1
let g:crunch_eval_type_bc     = 0
let g:crunch_eval_type_octave = 0

"mutually exclusive

"default is append
if !exists("g:crunch_result_type_append")
    let g:crunch_result_type_append  = 1
endif

"given a dummy value on each evaluation this value is reinitialized
let s:bang = ''


"only apply to vim & python
"default to on
" let s:option.float             = 1

" let s:option.sum             = 0
" let s:option.max             = 0
" let s:option.min             = 0
" let s:option.range           = 0
" let s:option.median          = 0
" let s:option.avg             = 0
" let s:option.mode            = 0
" let s:option.mean            = 0
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"MAIN FUNCTIONS{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"crunch#Crunch()                                                          {{{2
"When called opens a command window prompt for an equation to be evaluated
"Optionally can take input as a argument before opening a prompt
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Crunch(input)
    if a:input != ''
        let expr = a:input
    else
        let expr = s:GetInputString()
        redraw
    endif

    try
        if s:ValidLine(expr) == 0 | return | endif
        let result = crunch#core(expr)

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
        call s:EchoError(v:exception)
    endtry
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#Main()                                                            {{{2
" Captures the range for later use, Handles arguments, and then calls
" EvalLine
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Main(args) range
    call crunch#debug#PrintMsg(a:args. ' = the Argument(s)')

    call s:HandleArgs(a:args, a:firstline, a:lastline)

    execute a:firstline.','.a:lastline.'call crunch#EvalLine()'
    call crunch#debug#PrintMsg('Exclusive cleared')
    let s:isExclusive = 0
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#core()                                                            {{{2
" The core functionality of crunch 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#core(expression)
    let expr = s:FixMultiplication(a:expression)
    let expr = s:IntegerToFloat(expr)
    let expr = s:AddLeadingZero(expr)
    return s:EvalMath(expr)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#EvalLine()                                                        {{{2
" evaluates a line in a buffer, allowing for prefixes and suffixes
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#EvalLine()
    let origExpr = s:CrunchInit()
    try
        if s:ValidLine(origExpr) == 0 | return | endif
        let origExpr = s:RemoveOldResult(origExpr)
        let expr = s:ReplaceVariable(origExpr)
        let result  = crunch#core(expr)
    catch /Crunch error: /
        call s:EchoError(v:exception)
        let result= v:exception
    endtry

    call setline('.', s:prefix.origExpr.' = '.result.s:suffix)
    call crunch#debug#PrintMsg('['. result.'] is the result' )
    return result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#EvalPar()                                                       {{{2
"Evaluates a paragraph, equivalent to vip<leader>cl
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#EvalPar(args)
    call crunch#debug#PrintHeader('Crunch Paragraph Debug')
    execute "normal! vip\<ESC>"
    let topline = line("'<")
    let bottomline = line("'>")

    call crunch#debug#PrintMsg('['.a:args.'] is the variable' )
    execute topline."," bottomline."call "."crunch#Main(a:args)"
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#Dev()                                                             {{{2
"The top level function that handles arguments and user input
"TODO: elaborate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Dev(count, firstLine, lastLine, input, bang)
    let expr  = s:HandleArgss(a:input, a:bang)
    if expr != ''
        call crunch#Crunch(expr)
    else
        let expr = s:GetRange(a:count, a:firstLine, a:lastLine)
        if expr == ''
            call crunch#Crunch(expr)
        elseif g:crunchMode == "V"
            execute a:firstLine.','.a:lastLine.'call crunch#EvalLine()'
        else
            call crunch#Visual(expr)
        endif
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:HandleArgss()                                                          {{{2
" test if there is an arg in the correct form.
" return the arg if it's valid otherwise an empty string is returned
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:HandleArgss(input, bang)
    call crunch#debug#PrintHeader('Handle Args')
    call crunch#debug#PrintVarMsg(a:input,'the input')

    if a:bang == '!'
        let s:bang = a:bang
    else
        let s:bang = ''
    endif

    let options = split(matchstr(a:input, '\v^\s*(-\a+\ze\s+)+'), '\v\s+-')
    let expr = substitute(a:input, '\v\s*(-\a+\s+)+', '', 'g')

    call crunch#debug#PrintVarMsg(string(options),'the options')
    call crunch#debug#PrintVarMsg(expr,'the commandline expr')

    call s:SetOptions(options)

    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:SetOptions()                                                          {{{2
" 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:SetOptions(input)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:GetValidArg()                                                          {{{2
" TODO is this function even needed?
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetValidArg(input)
    call crunch#debug#PrintHeader('Get Valid Arguments')
    let arg = matchstr( a:input, '\C\v^\s*-\zs\a+\ze(\s+|$)')
    call crunch#debug#PrintMsg('The search engine name is =['.arg.']')
    return arg
endfunction



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"crunch#Visual()                                                     {{{2
"Takes string or mathematical expressions delimited by new lines 
"evaluates "each line individually and saving variables when they occur
"Finally, pasting over the selection or range
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Visual(exprs)
    call crunch#debug#PrintHeader('Inizilation')

    let exprList = split(a:exprs, '\n', 1)
    call crunch#debug#PrintVarMsg(string(exprList), 'List of expr')

    for i in range(len(exprList))
        call s:CaptureVariable(exprList[i])
        if s:ValidLine(exprList[i]) == 0 | continue | endif
        let exprList[i] = s:RemoveOldResult(exprList[i])
        let origExpr = exprList[i]
        let exprList[i] = s:ReplaceCapturedVariable(exprList[i])
        let result = crunch#core(exprList[i])
        let exprList[i] = s:BuildResult(origExpr, result)
        call s:CaptureVariable(exprList[i])
    endfor
    call crunch#debug#PrintMsg(string(exprList).'= the eprLinesList')
    let exprLines = join(exprList, "\n")
    call crunch#debug#PrintMsg(string(exprLines).'= the eprLines')
    call s:OverWriteVisualSelection(exprLines)
    let s:CapturedVariables = {}
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}

" INITILAZATION {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"s:HandleArgs()                                                           {{{2
"Interpret arguments to set flags accordingly
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:HandleArgs(args, fline, lline)
    call crunch#debug#PrintHeader('Handle Arguments Debug')
    call crunch#debug#PrintMsg('['.a:args.']= the arguments')

    if a:args !=# ''
        let  s:firstline = a:fline
        let  s:lastline  = a:lline
        if a:args ==# '-exclusive' || a:args ==# '-exc'
            call crunch#debug#PrintMsg('Exclusive set')
            let s:isExclusive = 1
        else
            call s:EchoError(s:ErrorTag ."'".a:args."' is not a valid argument")
        endif
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:CrunchInit()                                                           {{{2
"Gets the expression from current line, builds the suffix/prefix regex if
"need, and  removes the suffix and prefix from the expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:CrunchInit()
    call crunch#debug#PrintHeader('Crunch Inizilation Debug')

    let expr = getline('.')

    if !exists('b:filetype') || &filetype !=# b:filetype
        let b:filetype = &filetype
        call crunch#debug#PrintMsg('filetype set, rebuilding prefix/suffix regex')
        call crunch#debug#PrintMsg('['.&filetype.']= filetype')
        call s:BuildLinePrefix()
        call s:BuildLineSuffix()
    endif

    let s:suffix = matchstr(expr, b:suffixRegex)
    let s:prefix = matchstr(expr, b:prefixRegex)
    let expr = s:RemovePrefixNSuffix(expr)

    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:GetRange()                                                            {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetRange(count, firstLine, lastLine)
    call crunch#debug#PrintHeader('Get Range')
    if a:count == 0 "no range given extract from command call
        let result = ''
    else "range was given
        if g:crunchMode  =~ '\vV|v|'
            let result = s:GetVisualSelection()
            call crunch#debug#PrintVarMsg(result,'visual range')
        else 
            let result = join(getline(a:firstLine, a:lastLine), "\n") " search the range instead
            call crunch#debug#PrintVarMsg(result,'range')
        endif
    endif
    return result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:GetVisualSelection()                                                  {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetVisualSelection()
    try
        let a_save = getreg('a')
        normal! gv"ay
        return @a
    finally
        call setreg('a', a_save)
    endtry
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:OverWriteVisualSelection()                                            {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:OverWriteVisualSelection(input)
    let a_save = @a
    if g:crunchMode  =~ '\vV|v|'
        call setreg('a', a:input, g:crunchMode)
    else
        call setreg('a', a:input, 'b')
    endif 
    normal! gv"ap
    let @a = a_save
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}

"FORMAT EXPRESSION{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"s:ValidLine()                                                            {{{2
"Checks the line to see if it is a variable definition, or a blank line that
"may or may not contain whitespace.

"If the line is invalid this function returns false
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ValidLine(expr)
    call crunch#debug#PrintHeader('Valid Line')
    call crunch#debug#PrintMsg('[' . a:expr . ']= the tested string' )

    "checks for commented lines
    if a:expr =~ '\v^\s*'.g:crunch_calc_comment
        call crunch#debug#PrintMsg('test1 failed comment')
        return 0
    endif

    " checks for empty/blank lines
    if a:expr =~ '\v^\s*$'
        call crunch#debug#PrintMsg('test2 failed blank line')
        return 0
    endif

    " checks for lines that don't need evaluation
    if a:expr =~ '\v\C^\s*'.s:validVariable.'\s*\=\s*-?\s*'.s:numPat.'\s*$'
        call crunch#debug#PrintMsg('test3 failed dosnt need evaluation')
        return 0
    endif
    call crunch#debug#PrintMsg('It is a valid line!')
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
    call crunch#debug#PrintHeader('Remove Old Result')

    let expr = a:expr
    "if it's a variable declaration with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
    call crunch#debug#PrintMsg('[' . expr . ']= expression before removed result')

    let expr = substitute(expr, '\v\s*\=\s*('.s:numPat.')?\s*$', "", "")
    call crunch#debug#PrintMsg('[' . expr . ']= after removed old result')

    let expr = substitute(expr, '\v\s*\=\s*Crunch error:.*\s*$', "", "")
    call crunch#debug#PrintMsg('[' . expr . ']= after removed old error')

    let expr = substitute(expr, '\v^\s\+\ze?.', "", "")
    call crunch#debug#PrintMsg('[' . expr . ']= after removed whitespace')

    let expr = substitute(expr, '\v.\zs\s+$', "", "")
    call crunch#debug#PrintMsg('[' . expr . ']= after removed whitespace')

    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:FixMultiplication()                                                   {{{2
" turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:FixMultiplication(expr)
    call crunch#debug#PrintHeader('Fix Multiplication')

    "deal with ')( -> )*(', ')5 -> )*5' and 'sin(1)sin(1)'
    let expr = substitute(a:expr,'\v(\))\s*([(\.[:alnum:]])', '\1\*\2','g')
    call crunch#debug#PrintMsg('[' . expr . ']= fixed multiplication 1')

    "deal with '5sin( -> 5*sin(', '5( -> 5*( ', and  '5x -> 5*x'
    let expr = substitute(expr,'\v(\d)\s*([(a-df-zA-DF-Z])', '\1\*\2','g')
    call crunch#debug#PrintMsg('[' . expr . ']= fixed multiplication 2')

    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:IntegerToFloat()                                                      {{{2
" Convert Integers in the exprs to floats by calling a substitute
" command
" NOTE: from HowMuch.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:IntegerToFloat(expr)
    call crunch#debug#PrintHeader('Integer to Float')
    call crunch#debug#PrintMsg('['.a:expr.']= before int to float conversion')
    let expr = a:expr 
    let expr = substitute(expr,'\(^\|[^.0-9^eE]\)\zs\d\+\ze\([^.0-9]\|$\)', '&.0', 'g')
    call crunch#debug#PrintMsg('['.expr.']= after int to float conversion')
    return expr
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}

" HANDLE VARIABLES{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"s:CaptureVariables()                                                     {{{2
"TODO description
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:CaptureVariable(expr)
    call crunch#debug#PrintHeader('Capture Variable')

    let VarNamePat = '\v\C^\s*\zs'.s:validVariable.'\ze\s*\=\s*'
    let VarValuePat = '\v\=\s*\zs-?\s*'.s:numPat.'\ze\s*$' 

    let VarName = matchstr(a:expr, VarNamePat)
    let VarValue = matchstr(a:expr, VarValuePat)

    call crunch#debug#PrintVarMsg(VarName, 'the name of the variable')
    call crunch#debug#PrintVarMsg(VarValue, 'the value of the variable')

    if VarName != ''  && VarValue != ''
        let s:capturedVariables[VarName] = VarValue
        call crunch#debug#PrintVarMsg(string(s:capturedVariables), 'captured variables')
    endif

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:ReplaceVariable()                                                      {{{2
"Replaces the variable within an expression with the value of that variable
"inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ReplaceVariable(expr)
    call crunch#debug#PrintHeader('Replace Variable')

    let expr = a:expr
    call crunch#debug#PrintMsg("[".expr."]= expression before variable replacement ")

    " strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "")
    call crunch#debug#PrintMsg("[".expr."]= expression striped of variable")

    " replace variable with it's value
    let expr = substitute( expr, '\v('.s:validVariable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:GetVariableValue(submatch(1))', 'g' )

    call crunch#debug#PrintMsg("[".expr."]= expression after variable replacement")
    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:ReplaceCapturedVariable()                                      {{{2
"Replaces the variable within an expression with the value of that variable
"inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ReplaceCapturedVariable(expr)
    call crunch#debug#PrintHeader('Replace Captured Variable')

    let expr = a:expr
    call crunch#debug#PrintMsg("[".expr."]= expression before variable replacement ")

    " strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "")
    call crunch#debug#PrintMsg("[".expr."]= expression striped of variable")

    " replace variable with it's value
    let expr = substitute( expr, '\v('.s:validVariable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:capturedVariables[submatch(1)]', 'g' )

    call crunch#debug#PrintMsg("[".expr."]= expression after variable replacement")
    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:GetVariableValue()                                                     {{{2
"Searches for the value of a variable and returns the value assigned to the
"variable inspired by Ihar Filipau's inline calculator
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetVariableValue(variable)

    if a:variable =~ '\c^e\d*$'
        " TODO: make the E of e handling cleaner
        " if variable is e or E don't do anything
        return a:variable
    endif

    call crunch#debug#PrintHeader('Get Variable Value')
    call crunch#debug#PrintMsg("[".getline('.')."]= the current line")

    call crunch#debug#PrintMsg("[" . a:variable . "]= the variable")

    if s:isExclusive == 1
        call crunch#debug#PrintMsg("Searching with Stopline")
        call crunch#debug#PrintMsg("[".s:firstline."]= Stopline")
        let sline =search('\v\C^('.b:prefixRegex.
                    \ ')?\V'.a:variable.'\v\s*\=\s*', "bnW", (s:firstline -1))
    else
        let sline = search('\v\C^('.b:prefixRegex.
                    \ ')?\V'.a:variable.'\v\s*\=\s*' , "bnW")
    endif

    call crunch#debug#PrintMsg("[".sline."]= result of search for variable")
    if sline == 0
        call s:Throw("variable ".a:variable." not found")
    endif

    call crunch#debug#PrintMsg("[" .getline(sline). "]= line with variable value")
    let line = s:RemovePrefixNSuffix(getline(sline))
    call crunch#debug#PrintHeader('Get Variable Value Contiuned')

    let variableValue = matchstr(line,'\v\=\s*\zs-?\s*'.s:numPat.'\ze\s*$')
    call crunch#debug#PrintMsg("[" . variableValue . "]= the variable value")
    if variableValue == ''
        call s:Throw('value for '.a:variable.' not found.')
    endif

    return '('.variableValue.')'
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}

" RESULT HANDLING{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"s:BuildResult()                                                          {{{2
"Return Output
" append result (option: Append)
" replace result (option: Replace)
" append result of Statistical operation (option: Statistic)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildResult(expr, result)

    if s:bang == '!'
        if g:crunch_result_type_append  == 1
            let output = a:result
        else 
            let output = a:expr .' = '. a:result
        endif 
    else
        if g:crunch_result_type_append  == 1
            let output = a:expr .' = '. a:result
        else 
            let output = a:result
        endif 
    endif

    "TODO: insert statistical expression
    return output
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:AddLeadingZero()                                                      {{{2
" convert .5*.34 -> 0.5*0.34
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:AddLeadingZero(expr)
    let expr = a:expr
    call crunch#debug#PrintHeader('Add Leading Zero')
    call crunch#debug#PrintMsg('['.expr.']= before adding leading zero')
    let expr = substitute(expr,'\v(^|[^.0-9])\zs\.\ze([0-9])', '0&', 'g')
    call crunch#debug#PrintMsg('['.expr.']= after adding leading zero')
    return expr
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}

"PREFIX/SUFFIX {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"s:RemovePrefixNSuffix()                                                  {{{2
"Removes the prefix and suffix from a string
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RemovePrefixNSuffix(expr)
    let expr = a:expr
    call crunch#debug#PrintHeader('Remove Line Prefix and Suffix')

    call crunch#debug#PrintMsg('['.b:prefixRegex.']= the REGEX of the prefix/suffix')
    call crunch#debug#PrintMsg('['.b:suffixRegex.']= the REGEX of the suffix/suffix')
    call crunch#debug#PrintMsg('['.expr.']= expression BEFORE removing prefix/suffix')
    let expr = substitute(expr, b:prefixRegex, '', '')
    call crunch#debug#PrintMsg('['.expr.']= expression AFTER removing prefix')
    let expr = substitute(expr, b:suffixRegex, '', '')
    call crunch#debug#PrintMsg('['.expr.']= expression AFTER removing suffix')
    return expr
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:BuildLineSuffix()                                                      {{{2
"from a list of suffixes builds a regex expression for all suffixes in the
"list
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildLineSuffix()
    call crunch#debug#PrintHeader('Build Line Suffix')
    call crunch#debug#PrintMsg( "[".&commentstring."]=  the comment string ")
    let s:commentEnd = matchstr(&commentstring, '\v.+\%s\zs.*')

    "Build the suffix

    "Valid Line suffix list
    let s:Linesuffixs = ["*","//", s:commentEnd]
    let b:suffixRegex = ''
    let NumberOfsuffixes = len(s:Linesuffixs)

    "TODO replace with join() + map()
    for suffix in s:Linesuffixs
        " call crunch#debug#PrintMsg( "[".suffix."]= suffix to be added to regex")
        let b:suffixRegex = b:suffixRegex.escape(suffix,'\/')
        if NumberOfsuffixes !=1
            let b:suffixRegex = b:suffixRegex.'\|'
        endif

        call crunch#debug#PrintMsg( "[".b:suffixRegex."]= REGEX for all the suffixes")
        let NumberOfsuffixes -= 1
    endfor
    let b:suffixRegex= '\V\s\*\('.b:suffixRegex.'\)\=\s\*\$\v'

    "NOTE: this regex is very non magic see :h \V
    call crunch#debug#PrintMsg("[".b:suffixRegex."]= REGEX for all the suffixes")
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"s:BuildLinePrefix()                                                      {{{2
"from a list of prefixes builds a regex expression for all prefixes in the
"list
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildLinePrefix()

    call crunch#debug#PrintHeader('Build Line Prefix')
    call crunch#debug#PrintMsg( "[".&commentstring."]=  the comment string ")
    let s:commentStart = matchstr(&commentstring, '\v.+\ze\%s')

    "Build the prefix

    "Valid Line Prefix list
    let s:LinePrefixs = ["*","//", s:commentStart]
    let b:prefixRegex = ''
    let NumberOfPrefixes = len(s:LinePrefixs)


    "TODO replace with join() + map()
    for prefix in s:LinePrefixs
        " call crunch#debug#PrintMsg( "[".prefix."]= prefix to be added to regex")
        let b:prefixRegex = b:prefixRegex.escape(prefix,'\/')
        if NumberOfPrefixes !=1
            let b:prefixRegex = b:prefixRegex.'\|'
        endif

        call crunch#debug#PrintMsg( "[".b:prefixRegex."]= REGEX for the prefixes")
        let NumberOfPrefixes -= 1
    endfor
    let b:prefixRegex= '\V\^\s\*\('.b:prefixRegex.'\)\=\s\*\v'

    "NOTE: this regex is very non magic see :h \V
    call crunch#debug#PrintMsg("[".b:prefixRegex."]= REGEX for all the prefixes")
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" prompt the user for an expression
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetInputString()
    call inputsave()
    let expr = input(g:crunch_calc_prompt)
    call inputrestore()
    return expr
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2}}}

"EVALUATION {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"s:EvalMath()                                                             {{{2
"Return Output
" append result (option: Append)
" replace result (option: Replace)
" append result of Statistical operation (option: Statistic)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:EvalMath(expr)
    "a function pointers to the eval method
    "if python
    "if octave
    "if vimscript
    let result = s:VimEval(a:expr)
    return result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
" s:VimEval()                                                  {{{2
" Evaluates the expression and checks for errors in the process. Also
" if there is no error echo the result and save a copy of it to the default
" paste register
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:VimEval(expr)
    call crunch#debug#PrintHeader('Evaluate Expression')
    call crunch#debug#PrintMsg('[' . a:expr . "]= the final expression")

    let result = string(eval(a:expr))
    call crunch#debug#PrintMsg('['.result.']= before trailing ".0" removed')
    call crunch#debug#PrintMsg('['.matchstr(result,'\v\.0+$').']= trailing ".0"')

    "check for trailing '.0' in result and remove it (occurs with vim eval)
    if result =~ '\v\.0+$'
        let result = string(str2nr(result))
    endif

    return result
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}2
"}}}

"ERRORS{{{
"s:EchoError()                                                            {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:EchoError(errorString)
    echohl WarningMsg
    echomsg a:errorString
    echohl None
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"s:Throw()                                                                {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function!  s:Throw(errorBody) abort
    let ErrorMsg = s:ErrorTag.a:errorBody
    throw ErrorMsg
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
"Restore settings                                                          {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let &cpo = save_cpo

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
" vim:foldmethod=marker
