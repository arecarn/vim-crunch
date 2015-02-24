""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Maintainer: Ryan Carney
"Repository: https://github.com/arecarn/crunch
"License: WTFPL
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"SCRIPT SETTINGS {{{
let saveCpo = &cpo
set cpo&vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"GLOBALS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"Holds the variables captured in a range/selection
let s:variables = {}

let s:validVariable = '\v[a-zA-Z_]+[a-zA-Z0-9_]*'

"Number Regex Patterns
let sign = '\v[-+]?'
let number = '\v\.\d+|\d+%([.]\d+)?'
let eNotation = '\v%([eE][+-]?\d+)?'
let s:numPat = sign . '%(' . number . eNotation . ')'

let s:errorTag = 'Crunch error: '
let s:isExclusive = 0
let s:bang = ''


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"MAIN FUNCTIONS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#CmdLineCrunch(input) "{{{2
    """
    "When called opens a command window prompt for an equation to be evaluated
    "Optionally can take input as a argument before opening a prompt
    """

    if a:input != ''
        let expr = a:input
    else
        let expr = s:GetInputString()
        redraw
    endif

    try
        if s:ValidLine(expr) == 0 | return | endif
        let result = crunch#Core(expr)

        echo expr." = ".result

        if has('clipboard')
            echo "Yanked Result"
            "yank the result into the correct register
            if match(&clipboard, '\C\vunnamed') != -1
                call setreg('*', result, 'c')
            endif
            if match(&clipboard, '\C\vunnamedplus') != -1
                call setreg('+', result, 'c')
            endif
            if match(&clipboard, '\C\vunnamedplus|unamed') == -1
                call setreg('"', result, 'c')
            endif
        endif

    catch /Crunch error: /
        call s:EchoError(v:exception)
    endtry
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Eval(exprs) "{{{2
    """
    "Takes string of mathematical expressions delimited by new lines
    "evaluates "each line individually while saving variables when they occur
    """

    call util#debug#PrintHeader('Inizilation')
    let s:variables = g:crunch_user_variables

    let exprList = split(a:exprs, '\n', 1)
    call util#debug#PrintVarMsg(string(exprList), 'List of expr')

    for i in range(len(exprList))
        try
            let origLine = exprList[i]
            let exprList[i] = s:CrunchInit(exprList[i])
            call s:CaptureVariable(exprList[i])
            if s:ValidLine(exprList[i]) == 0
                let exprList[i] = origLine
                continue
            endif
            let exprList[i] = s:RemoveOldResult(exprList[i])
            let origExpr = exprList[i]
            let exprList[i] = s:MarkENotation(exprList[i])
            let exprList[i] = s:ReplaceCapturedVariable(exprList[i])
            let exprList[i] = s:ReplaceVariable2(exprList[i], i)
            let exprList[i] = s:UnmarkENotation(exprList[i])
            let result  = crunch#Core(exprList[i])
        catch /Crunch error: /
            call s:EchoError(v:exception)
            let result= v:exception
        endtry
        let exprList[i] = s:BuildResult(origExpr, result)
    endfor
    call util#debug#PrintMsg(string(exprList).'= the exprLinesList')
    let exprLines = join(exprList, "\n")
    call util#debug#PrintMsg(string(exprLines).'= the exprLines')
    let s:variables = {}
    return exprLines
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Command(count, firstLine, lastLine, cmdInput, bang) abort "{{{2
    """
    "The top level function that handles arguments and user input
    """

    let cmdInputExpr  = s:HandleCmdInput(a:cmdInput, a:bang)

    if cmdInputExpr != '' "an expression was passed in
        "TODO only call this once if possible 03 May 2014
        call crunch#CmdLineCrunch(cmdInputExpr)
    else "no command was passed in

        try
            let s:selection = selection#New(a:count, a:firstLine, a:lastLine)
        catch
            call s:Throw('Please install selection.vim for this operation')
        endtry

        if s:selection.content == '' "no lines or Selection was returned
            call crunch#CmdLineCrunch(s:selection.content)
        else
            call s:selection.OverWrite(crunch#Eval(s:selection.content))
        endif
    endif
    let s:bang = '' "TODO refactor
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Core(expression) "{{{2
    """
    "The core functionality of crunch
    """

    let expr = s:FixMultiplication(a:expression)
    let expr = s:IntegerToFloat(expr)
    let expr = s:AddLeadingZero(expr)
    return s:EvalMath(expr)
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#Operator(type) "{{{2
    """
    """

    call util#debug#PrintHeader('Operator')
    "backup settings that we will change
    let selSave = &selection
    let cbSave = &clipboard

    "make selection and clipboard work the way we need
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus

    "backup the unnamed register, which we will be yanking into
    let regSave = @@

    call util#debug#PrintVarMsg(string(a:type), 'Operator Selection Type')
    "yank the relevant text, and also set the visual selection (which will be reused if the text
    "needs to be replaced)
    if a:type =~ '^\d\+$'
        "if type is a number, then select that many lines
        silent exe 'normal! V'.a:type.'$y'

    elseif a:type =~ '^.$'
        "if type is 'v', 'V', or '<C-V>' (i.e. 0x16) then reselect the visual region
        silent exe "normal! `<" . a:type . "`>y"
        call util#debug#PrintMsg('catch all type')
        let type=a:type

    elseif a:type == 'block'
        "block-based text motion
        silent exe "normal! `[\<C-V>`]y"
        call util#debug#PrintMsg('block type')
        let type=''

    elseif a:type == 'line'
        "line-based text motion
        silent exe "normal! `[V`]y"
        let type='V'
    else
        "char-based text motion
        silent exe "normal! `[v`]y"
        let type='v'
    endif

    let regtype = type
    call util#debug#PrintVarMsg(regtype, "the regtype")
    let repl = crunch#Eval(@@)

    "if the function returned a value, then replace the text
    if type(repl) == 1
        "put the replacement text into the unnamed register, and also set it to be a
        "characterwise, linewise, or blockwise selection, based upon the selection type of the
        "yank we did above
        call setreg('@', repl, regtype)
        "reselect the visual region and paste
        normal! gvp
    endif

    "restore saved settings and register value
    let @@ = regSave
    let &selection = selSave
    let &clipboard = cbSave
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"INITIALIZATION {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:CrunchInit(expr) "{{{2
    """
    "Gets the expression from current line, builds the suffix/prefix regex if
    "need, and  removes the suffix and prefix from the expression
    """

    call util#debug#PrintHeader('Crunch Inizilation Debug')

    let expr = a:expr

    if !exists('b:filetype') || &filetype !=# b:filetype
        let b:filetype = &filetype
        call util#debug#PrintMsg('filetype set, rebuilding prefix/suffix regex')
        call util#debug#PrintMsg('['.&filetype.']= filetype')
        call s:BuildPrefixAndSuffixRegex()
    endif

    let s:prefix = matchstr(expr, b:prefixRegex)
    call util#debug#PrintVarMsg(s:prefix, "s:prefix")
    call util#debug#PrintVarMsg(b:prefixRegex, "prefix regex")

    let s:suffix = matchstr(expr, b:suffixRegex)
    call util#debug#PrintVarMsg(s:suffix, "s:suffix")
    call util#debug#PrintVarMsg(b:suffixRegex, "suffix regex")

    let expr = s:RemovePrefixNSuffix(expr)

    return expr
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:HandleCmdInput(cmdInput, bang) "{{{2
    """
    "test if there is an arg in the correct form.
    "return the arg if it's valid otherwise an empty string is returned
    """

    call util#debug#PrintHeader('Handle Args')
    call util#debug#PrintVarMsg(a:cmdInput,'the cmdInput')

    "was there a bang after the command?
    let s:bang = a:bang

    "find command switches in the expression and extract them into a list
    let options = split(matchstr(a:cmdInput, '\v^\s*(-\a+\ze\s+)+'), '\v\s+-')
    call util#debug#PrintVarMsg(string(options),'the options')

    "remove the command switches from the cmdInput
    let expr = substitute(a:cmdInput, '\v\s*(-\a+\s+)+', '', 'g')
    call util#debug#PrintVarMsg(expr,'the commandline expr')

    return expr
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"FORMAT EXPRESSION{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ValidLine(expr) "{{{2
    """
    "Checks the line to see if it is a variable definition, or a blank line
    "that may or may not contain whitespace. If the line is invalid this
    "function returns false
    """

    call util#debug#PrintHeader('Valid Line')
    call util#debug#PrintMsg('[' . a:expr . ']= the tested string' )

    "checks for commented lines
    if a:expr =~ '\v^\s*'.g:crunch_comment
        call util#debug#PrintMsg('test1 failed comment')
        return 0
    endif

    "checks for empty/blank lines
    if a:expr =~ '\v^\s*$'
        call util#debug#PrintMsg('test2 failed blank line')
        return 0
    endif

    "checks for lines that don't need evaluation
    if a:expr =~ '\v\C^\s*'.s:validVariable.'\s*\=\s*-?\s*'.s:numPat.'\s*$'
        call util#debug#PrintMsg('test3 failed dosnt need evaluation')
        return 0
    endif
    call util#debug#PrintMsg('It is a valid line!')
    return 1
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RemoveOldResult(expr) "{{{2
    """
    "Remove old result if any
    "eg '5+5 = 10' becomes '5+5'
    "eg 'var1 = 5+5 =10' becomes 'var1 = 5+5'
    "inspired by Ihar Filipau's inline calculator
    """

    call util#debug#PrintHeader('Remove Old Result')

    let expr = a:expr
    "if it's a variable declaration with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
    call util#debug#PrintMsg('[' . expr . ']= expression before removed result')

    let expr = substitute(expr, '\v\s*\=\s*('.s:numPat.')?\s*$', "", "")
    call util#debug#PrintMsg('[' . expr . ']= after removed old result')

    let expr = substitute(expr, '\v\s*\=\s*Crunch error:.*\s*$', "", "")
    call util#debug#PrintMsg('[' . expr . ']= after removed old error')

    let expr = substitute(expr, '\v^\s\+\ze?.', "", "")
    call util#debug#PrintMsg('[' . expr . ']= after removed whitespace')

    let expr = substitute(expr, '\v.\zs\s+$', "", "")
    call util#debug#PrintMsg('[' . expr . ']= after removed whitespace')

    return expr
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:FixMultiplication(expr) "{{{2
    """
    "turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'
    """

    call util#debug#PrintHeader('Fix Multiplication')

    "deal with ')( -> )*(', ')5 -> )*5' and 'sin(1)sin(1)'
    let expr = substitute(a:expr,'\v(\))\s*([(\.[:alnum:]])', '\1\*\2','g')
    call util#debug#PrintMsg('[' . expr . ']= fixed multiplication 1')

    "deal with '5sin( -> 5*sin(', '5( -> 5*( ', and  '5x -> 5*x'
    let expr = substitute(expr,'\v(\d)\s*([(a-df-zA-DF-Z])', '\1\*\2','g')
    call util#debug#PrintMsg('[' . expr . ']= fixed multiplication 2')

    return expr
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:IntegerToFloat(expr) "{{{2
    """
    "Convert Integers in the exprs to floats by calling a substitute
    "command
    "NOTE: from HowMuch.vim
    """

    call util#debug#PrintHeader('Integer to Float')
    call util#debug#PrintMsg('['.a:expr.']= before int to float conversion')
    let expr = a:expr
    let expr = substitute(expr,'\(^\|[^.0-9]\)\zs\([eE]-\?\)\@<!\d\+\ze\([^.0-9]\|$\)', '&.0', 'g')
    call util#debug#PrintMsg('['.expr.']= after int to float conversion')
    return expr
endfunction "}}}2

"E NOTATION {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:MarkENotation(expr) "{{{3
    """
    "e.g
    "5e3  -> 5#3
    "5e-3 -> 5#-3
    """

    let expr = a:expr
    let number = '\v(\.\d+|\d+([.]\d+)?)\zs[eE]\ze[+-]?\d+'
    let expr = substitute(expr, number, '#', 'g')
    return expr
endfunction  "}}}3


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:UnmarkENotation(expr) "{{{3
    """
    "e.g
    "5#3  -> 5e3
    "5#-3 -> 5e-3
    """

    let expr = a:expr
    call util#debug#PrintVarMsg(expr, 'before Unmarking E notation')
    "put back the e and remove the following ".0"
    let expr = substitute(expr, '\v#([-]?\d+)(\.0)?', 'e\1', 'g')
    call util#debug#PrintVarMsg(expr, 'after Unmarking E notation')
    return expr
endfunction! "}}}3
"}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"HANDLE VARIABLES {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:CaptureVariable(expr) "{{{2
    """
    """

    call util#debug#PrintHeader('Capture Variable')

    let VarNamePat = '\v\C^\s*\zs'.s:validVariable.'\ze\s*\=\s*'
    let VarValuePat = '\v\=\s*\zs-?\s*'.s:numPat.'\ze\s*$'

    let VarName = matchstr(a:expr, VarNamePat)
    let VarValue = matchstr(a:expr, VarValuePat)

    call util#debug#PrintVarMsg(VarName, 'the name of the variable')
    call util#debug#PrintVarMsg(VarValue, 'the value of the variable')

    if VarName != ''  && VarValue != ''
        let s:variables[VarName] = '('.VarValue.')'
        call util#debug#PrintVarMsg(string(s:variables), 'captured variables')
    endif
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ReplaceCapturedVariable(expr) "{{{2
    """
    """

    call util#debug#PrintHeader('Replace Captured Variablee')

    let expr = a:expr
    call util#debug#PrintMsg("[".expr."]= expression before variable replacement ")

    "strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "")
    call util#debug#PrintMsg("[".expr."]= expression striped of variable")

    let variableRegex = '\v('.s:validVariable .'\v)\ze([^(a-zA-Z0-9_]|$)' "TODO move this up to the top
    "replace variable with it's value
    let expr = substitute(expr, variableRegex,
                \ '\=s:GetVariableValue3(submatch(1))', 'g' )

    call util#debug#PrintMsg("[".expr."]= expression after variable replacement")
    return expr
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ReplaceVariable(expr) "{{{2
    """
    "Replaces the variable within an expression with the value of that
    "variable inspired by Ihar Filipau's inline calculator
    """

    call util#debug#PrintHeader('Replace Variable')

    let expr = a:expr
    call util#debug#PrintMsg("[".expr."]= expression before variable replacement ")

    "strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "")
    call util#debug#PrintMsg("[".expr."]= expression striped of variable")

    "replace variable with it's value
    let expr = substitute( expr, '\v('.s:validVariable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:GetVariableValue(submatch(1))', 'g' )

    call util#debug#PrintMsg("[".expr."]= expression after variable replacement")
    return expr
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetVariableValue3(variable) abort
    """
    """

    let value = get(s:variables, a:variable, "not found")
    if value == "not found"
        "call s:Throw("value for ".a:variable." not found")
        return a:variable
    endif

    return value
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetVariableValue(variable) "{{{2
    """
    """

    call util#debug#PrintHeader('Get Variable Value')
    call util#debug#PrintMsg("[".getline('.')."]= the current line")

    call util#debug#PrintMsg("[" . a:variable . "]= the variable")

    let sline = search('\v\C^('.b:prefixRegex.
                \ ')?\V'.a:variable.'\v\s*\=\s*' , "bnW")

    call util#debug#PrintMsg("[".sline."]= result of search for variable")
    if sline == 0
        call s:Throw("variable ".a:variable." not found")
    endif

    call util#debug#PrintMsg("[" .getline(sline). "]= line with variable value")
    let line = s:RemovePrefixNSuffix(getline(sline))
    call util#debug#PrintHeader('Get Variable Value Contiuned')

    let variableValue = matchstr(line,'\v\=\s*\zs-?\s*'.s:numPat.'\ze\s*$')
    call util#debug#PrintMsg("[" . variableValue . "]= the variable value")
    if variableValue == ''
        call s:Throw('value for '.a:variable.' not found')
    endif

    return '('.variableValue.')'
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ReplaceVariable2(expr, num) "{{{2
    """
    """

    call util#debug#PrintHeader('Replace Variable 2')

    let expr = a:expr
    call util#debug#PrintMsg("[".expr."]= expression before variable replacement ")

    "strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:validVariable.'\s*\=\s*', "", "")
    call util#debug#PrintMsg("[".expr."]= expression striped of variable")

    "replace variable with it's value
    let expr = substitute( expr, '\v('.s:validVariable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:GetVariableValue2(submatch(1), a:num)', 'g' )

    call util#debug#PrintMsg("[".expr."]= expression after variable replacement")
    return expr
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetVariableValue2(variable, num) "{{{2
    """
    """

    call util#debug#PrintMsg("[".a:num."]= is the num")
    call util#debug#PrintMsg("[".a:variable."]= is the variable to be replaced")
    let sline = search('\v\C^('.b:prefixRegex.')?\V'.a:variable.'\v\s*\=\s*',
                \"bnW" )

    call util#debug#PrintMsg("[".sline."]= search line")

    let line = s:RemovePrefixNSuffix(getline(sline))
    let variableValue = matchstr(line,'\v\=\s*\zs-?\s*'.s:numPat.'\ze\s*$')
    call util#debug#PrintMsg("[" . variableValue . "]= the variable value")
    if variableValue == ''
        call s:Throw("value for ".a:variable." not found")
    else
        return '('.variableValue.')'
    endif
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"RESULT HANDLING{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildResult(expr, result) "{{{2
    """
    """
    let output = a:expr .' = '. a:result

    "capture variable results if they exists TODO refactor
    call s:CaptureVariable(output)

    "bang isn't used and type is not append result
    if (s:bang == '!' && g:crunch_result_type_append)
                \|| (s:bang == '' && !g:crunch_result_type_append)
        let output = a:result
    endif
    call util#debug#PrintVarMsg(s:prefix, "s:prefix")
    call util#debug#PrintVarMsg(s:suffix, "s:suffix")
    call util#debug#PrintVarMsg(output, "output")
    return s:prefix.output.s:suffix
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:AddLeadingZero(expr) "{{{2
    """
    "convert .5*.34 -> 0.5*0.34
    """

    let expr = a:expr
    call util#debug#PrintHeader('Add Leading Zero')
    call util#debug#PrintMsg('['.expr.']= before adding leading zero')
    let expr = substitute(expr,'\v(^|[^.0-9])\zs\.\ze([0-9])', '0&', 'g')
    call util#debug#PrintMsg('['.expr.']= after adding leading zero')
    return expr
endfunction "}}}2


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"PREFIX/SUFFIX {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RemovePrefixNSuffix(expr) "{{{2
    """
    "Removes the prefix and suffix from a string
    """

    let expr = a:expr
    call util#debug#PrintHeader('Remove Line Prefix and Suffix')

    call util#debug#PrintMsg('['.b:prefixRegex.']= the REGEX of the prefix')
    call util#debug#PrintMsg('['.b:suffixRegex.']= the REGEX of the suffix')
    call util#debug#PrintMsg('['.expr.']= expression BEFORE removing prefix/suffix')
    let expr = substitute(expr, b:prefixRegex, '', '')
    call util#debug#PrintMsg('['.expr.']= expression AFTER removing prefix')
    let expr = substitute(expr, b:suffixRegex, '', '')
    call util#debug#PrintMsg('['.expr.']= expression AFTER removing suffix')
    return expr
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:BuildPrefixAndSuffixRegex() "{{{2
    """
    "from a list of suffixes builds a regex expression for all suffixes in the
    "list
    """
    call util#debug#PrintHeader('Build Line Prefix')
    call util#debug#PrintMsg( "[".&commentstring."]=  the comment string ")
    let s:commentStart = matchstr(&commentstring, '\v.+\ze\%s')
    let s:prefixs = ['*','//', s:commentStart]
    call filter (s:prefixs, "v:val != ''")
    call util#debug#PrintVarMsg(string(s:prefixs), "s:prefixs")
    let b:prefixRegex = join( map(copy(s:prefixs), 'escape(v:val, ''\/'')'), '\|')
    call util#debug#PrintMsg("[".b:prefixRegex."]= REGEX for the prefixes")
    let b:prefixRegex= '\V\^\s\*\('.b:prefixRegex.'\)\=\s\*\v'

    call util#debug#PrintHeader('Build Line Suffix')
    call util#debug#PrintMsg( "[".&commentstring."]=  the comment string ")
    let s:commentEnd = matchstr(&commentstring, '\v.+\%s\zs.*')
    let s:suffixs = ['//', s:commentEnd]
    call filter (s:suffixs, "v:val != ''")
    call util#debug#PrintVarMsg(string(s:suffixs), "s:suffixs")
    let b:suffixRegex = join( map(copy(s:suffixs), 'escape(v:val, ''\/'')'), '\|')
    call util#debug#PrintMsg( "[".b:suffixRegex."]= REGEX for suffixes ")
    let b:suffixRegex= '\V\[^ ]\{-1,}\zs\s\*\(\('.b:suffixRegex.'\)\.\*\)\=\s\*\$\v'

    "NOTE: these regex is very non magic see :h \V
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GetInputString() "{{{2
    """
    "prompt the user for an expression
    """

    call inputsave()
    let expr = input(g:crunch_prompt)
    call inputrestore()
    return expr
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"EVALUATION {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:EvalMath(expr) "{{{2
    """
    "Return Output
    "append result (option: Append)
    "replace result (option: Replace)
    "append result of Statistical operation (option: Statistic)
    "a function pointers to the eval method
    "if python
    "if octave
    "if vimscript
    """

    let result = s:VimEval(a:expr)
    return result
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:VimEval(expr) "{{{2
    """
    "Evaluates the expression and checks for errors in the process. Also
    "if there is no error echo the result and save a copy of it to the default
    "paste register
    """

    call util#debug#PrintHeader('Evaluate Expression')
    call util#debug#PrintMsg('[' . a:expr . "]= the final expression")

    let result = string(eval(a:expr))
    call util#debug#PrintMsg('['.result.']= before trailing ".0" removed')
    call util#debug#PrintMsg('['.matchstr(result,'\v\.0+$').']= trailing ".0"')

    "check for trailing '.0' in result and remove it (occurs with vim eval)
    if result =~ '\v\.0+$'
        let result = string(str2nr(result))
    endif

    return result
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

"ERRORS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:EchoError(errorString) "{{{2
    """
    """

    echohl WarningMsg
    echomsg a:errorString
    echohl None
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function!  s:Throw(errorBody) abort "{{{2
    """
    """

    let ErrorMsg = s:errorTag.a:errorBody
    throw ErrorMsg
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

let &cpo = saveCpo
" vim:foldmethod=marker
