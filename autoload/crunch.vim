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
"Globals + Dev Variable                                                    {{{
" The Top Level Function that determines program flow
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
"=============================================================================
"crunch_debug enables varies echoes throughout the code
"=============================================================================
let s:debug = 1

"==========================================================================}}}
" s:PrintDebugHeader()                                                     {{{
"=============================================================================
function! s:PrintDebugHeader(text)
    if s:debug 
        echom "                                                                                " 
        echom "================================================================================" 
        echom a:text . " Debug"
        echom '--------------------------------------------------------------------------------'
    endif
endfunction

"==========================================================================}}}
" s:PrintDebugMessage()                                                    {{{
"=============================================================================
function! s:PrintDebugMessage(text)
    if s:debug 
        echom a:text
    endif
endfunction

"==========================================================================}}}
"s:Crunch                                                                  {{{
" The Top Level Function that determines program flow
"=============================================================================
function! crunch#Crunch(input) 
    if a:input != ''
        let OriginalExpression = a:input
    else
        let OriginalExpression = s:GetInputString()
    endif
    if s:ValidInput(OriginalExpression) == 0 | return | endif
    let expression = s:RemoveOldResult(OriginalExpression)
    let expression = s:Core(expression)
    let result = s:EvaluateExpression(expression)
endfunction

"==========================================================================}}}
"s:CrunchLine                                                              {{{
" The Top Level Function that determines program flow
"=============================================================================
function! crunch#CrunchLine(line) 
    let OriginalExpression = getline(a:line)
    if s:ValidLine(OriginalExpression) == 0 | return | endif
    let OriginalExpression = s:RemoveOldResult(OriginalExpression)
    let expression = s:ReplaceTag(OriginalExpression)
    call s:PrintDebugMessage('['. OriginalExpression . '] is the OriginalExpression' )
    let expression = s:Core(expression)
    let resultStr = s:EvaluateExpressionLine(expression)
    call setline(a:line, OriginalExpression.' = '.resultStr)
    call s:PrintDebugMessage('['. resultStr . '] is the result' )
    return resultStr
endfunction

"==========================================================================}}}
"s:CrunchBlock                                                             {{{
" The Top Level Function that determines program flow
"=============================================================================
function! crunch#CrunchBlock() range
    let top = a:firstline
    let bot = a:lastline
    call s:PrintDebugMessage("range: " . top . ", " . bot) 
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
        call s:PrintDebugMessage("new range: " . top . ", " . bot) 
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
    let expression = substitute(expression, '\(\d*\.\=\d\+\)', '\=str2float(submatch(0))' , 'g')
    call s:PrintDebugMessage('[' . expression . '] = is the expression converted to floats' )
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

    let result = 1

    call s:PrintDebugMessage('[' . a:expression . '] = the tested string' )

    "checks for blank lines
    if a:expression == '' | let result = 0 | endif 
    call s:PrintDebugMessage('[' . matchstr(a:expression, '') . "] = is the match for blank lines, result = " . result )

    "checks for commented lines
    if matchstr(a:expression, "^\s*" . g:crunch_calc_comment . ".*$") !='' | let result = 0 | endif 
    call s:PrintDebugMessage('[' . matchstr(a:expression, "^\s*" . g:crunch_calc_comment . ".*$") . "] = is the match for comment lines result = " . result )

    " checks for empty lines
    if matchstr(a:expression, '^\s\+$') !='' | let result = 0 | endif 
    call s:PrintDebugMessage('[' . matchstr(a:expression, '^\s\+$') . "] = is the match for empty lines, result = " . result )

    " checks for tag lines that don't need evaluation
    let test = matchstr(a:expression, '^\s*var\s\+\a\+\s*=\s*[0-9.]\+$') 
    if test !='' | let result = 0 | endif
    call s:PrintDebugMessage('[' . matchstr(a:expression, '^\s*var\s*\a\+\s*=\s*[0-9.]\+$') . "] = is the match for tag lines result = " . result )

    return result
endfunction


"==========================================================================}}}
"s:ValidInput                                                              {{{
"Checks the line to see if it is a variable definition, or a blank line that
"may or may not contain whitespace. 

"If the line is invalid this function returns false
"=============================================================================
function! s:ValidInput(expression) 
    call s:PrintDebugHeader('Valid Input')

    let result = 1
    call s:PrintDebugMessage('[' . a:expression . '] = the tested string' )

    "checks for blank lines
    if a:expression == '' | let result = 0 | endif 
    call s:PrintDebugMessage('[' . matchstr(a:expression, '') . "] = is the match for blank lines, result = " . result )

    " checks for empty lines
    if matchstr(a:expression, '^\s\+$') !='' | let result = 0 | endif 
    call s:PrintDebugMessage('[' . matchstr(a:expression, '^\s\+$') . "] = is the match for empty lines, result = " . result )

    return result
endfunction

"==========================================================================}}}
"s:ReplaceTag                                                              {{{
"Replaces the tag within an expression with the value of that tag
"inspired by Ihar Filipau's incline calculator
"=============================================================================
function! s:ReplaceTag(expression) 
    call s:PrintDebugHeader('Replace Tag')

    let e = a:expression
    call s:PrintDebugMessage("[" . e . "] = expression before tag replacement " )

    " strip the variable marker, if any
    let e = substitute( e, '^\s*var\s\+\a\+\s*=\s*', "", "" )
    call s:PrintDebugMessage("[" . e . "] = expression striped of tag") 

    " replace values by the tag
    let e = substitute( e, '\(\a\+\)\ze\([^(a-zA-z]\|$\)', '\=s:GetTagValue(submatch(1))', 'g' )

    call s:PrintDebugMessage("[" . e . "] = expression after tag replacement ") 
    return e
endfunction

"==========================================================================}}}
"s:GetTagValue                                                             {{{
"Searches for the value of a tag and returns the value assigned to the tag
"inspired by Ihar Filipau's incline calculator
"=============================================================================
function! s:GetTagValue(tag)
    call s:PrintDebugHeader('Get Tag Value')

    "TODO need to consider ignorecase smartcase and magic
    call s:PrintDebugMessage("[" . a:tag . "] = the tag") 

    "bnW => b = search backwards, n = don't move cursor, W => don't wrap around file
    let s = search( '^\s*var\s\+' . a:tag . '\s*=\s*' , "bnW" )
    call s:PrintDebugMessage("[" . search( '^\s*var\s\+' . a:tag . '\s*=\s*' , "bn" ) . "] = result of search for tag") 

    try
        if s == 0 
            throw "Crunch error: tag ".a:tag." not found" 
        endif
    endtry

    " avoid substitute() as we are called from inside substitute()
    let line = getline( s )
    call s:PrintDebugMessage("[" . line . "] = line with tag value") 

    "TODO reevaluate tag expression here 

    let idx = strridx( line, "=" )
    try
        if idx == -1 
            throw "Crunch error: line with tag ".a:tag." doesn't contain the '='" 
        endif
    endtry
    let tagvalue= strpart( line, idx+1 )
    call s:PrintDebugMessage("[" . tagvalue . "] = the tag value") 
    return tagvalue
endfunction


"==========================================================================}}}
"s:RemoveOldResult                                                         {{{
"Remove old result if any eg '5+5 = 10' becomes '5+5'
"inspired by Ihar Filipau's incline calculator
"=============================================================================
function! s:RemoveOldResult(expression)
    call s:PrintDebugHeader('Remove Old Result')

    let e = a:expression
    "if it's a variable with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
    call s:PrintDebugMessage('[' . e . ']= expression before removed result')

    let e = substitute( e, '\s\+$', "", "" )
    call s:PrintDebugMessage('[' . e . ']= expression after removed trailing space')

    let e = substitute( e, '\s*=\s*[-0-9e.]*\s*$', "", "" )
    call s:PrintDebugMessage('[' . e . ']= expression after removed old result')

    call s:PrintDebugMessage('[' . e . ']= expression after removed result')

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
    let s:e = substitute(a:expression,'\([0-9.]\+\)\^\([0-9.]\+\)', 'pow(\1,\2)','g') " good
    let s:e = substitute(s:e, '\(\a\+(.\{-})\)\^\([0-9.]\+\)', 'pow(\1,\2)','g') "questionable 
    let s:e = substitute(s:e, '\([0-9.]\+\)\^\(\a\+(.\{-})\)', 'pow(\1,\2)','g') "good 
    let s:e = substitute(s:e, '\(\a\+(.\{-})\)\^\(\a\+(.\{-})\)' , 'pow(\1,\2)','g') "bad
    return s:e
endfunction

"==========================================================================}}}
" s:FixMultiplication                                                      {{{
" turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'
"=============================================================================
function! s:FixMultiplication(expression)
    call s:PrintDebugHeader('Fix Multiplication')


    "deal with )( -> )*(
    let e = substitute(a:expression,'\()\)\s*\((\)', '\1\*\2','g')
    call s:PrintDebugMessage('[' . e . ']= fixed multiplication 1') 

    "deal with sin(1)sin(1)
    let e = substitute(e,'\()\)\s*\(\a\+\)', '\1\*\2','g')
    call s:PrintDebugMessage('[' . e . ']= fixed multiplication 2') 

    "deal with 5sin( -> 5*sin(
    " '\(\d\+\(\.\d\+\)\=\)'
    let e = substitute(e,'\([0-9.]\+\)\s*\(\a\+\)', '\1\*\2','g')
    call s:PrintDebugMessage('[' . e . ']= fixed multiplication 3') 

    "deal with )5 -> )*5
    let e = substitute(e, '\()\)\s*\(\d*\.\{0,1}\d\+\)', '\1\*\2', 'g')

    "deal with 5( -> 5*(
    let e = substitute(e, '\([0-9.]\+\)\s*\((\)', '\1\*\2', 'g')
    call s:PrintDebugMessage('[' . e . ']= fixed multiplication 5') 
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
    call s:PrintDebugMessage(']' . a:expression . "]= the final expression") 

    let errorFlag = 0
    " try
    if s:crunch_using_octave == 1
        let result = s:OctaveEval(a:expression)
    else
        let result = string(eval(a:expression))
    endif
    call s:PrintDebugMessage('[' . matchstr(result,"\\.0$") . '] is the matched string' )
    if matchstr(result,"\\.0$") == ".0" "matches the 10 in 8e10 for some reason 
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
    redraw
    echo a:expression
    echo "= " . result
    echo "Yanked Result"

    "yank the result into the correct register
    if &cb == 'unnamed'
        let @* = result
    elseif &cb == 'unnamedplus'
        let @+ = result
    else
        let @" = result
    endif

    "endif
    return result
endfunction

"==========================================================================}}}
" s:EvaluateExpressionLine                                                 {{{
" Evaluates the expression and checks for errors in the process. Also 
" if there is no error echo the result and save a copy of it to the default 
" register
"=============================================================================
function! s:EvaluateExpressionLine(expression)
    call s:PrintDebugHeader('Evaluate Expression Line')

    call s:PrintDebugMessage(']' . a:expression . "]= the final expression") 
    let errorFlag = 0
    " try

    if s:crunch_using_octave == 1
        let result = s:OctaveEval(a:expression)
    elseif s:crunch_using_vimscript == 1
        let result = string(eval(a:expression))
    else
        let s:crunch_using_vimscript
        let result = string(eval(a:expression))
    endif


    call s:PrintDebugMessage('[' . matchstr(result,"\\.0$") . '] is the matched string' )
    call s:PrintDebugMessage(" this this the final result before intization") 
    "check for a ".0" at the end of a number and remove it 
    if matchstr(result,"\\.0$") == ".0" 
        call s:PrintDebugMessage("\.0$" . '] is the matched string') 
        let result = string(str2nr(result))
        call s:PrintDebugMessage(" this this the final result after intization") 
    endif

    " catch /^Vim\%((\a\+)\)\=:E/	"catch all Vim errors
    "     let errorFlag = 1
    " endtry
    " if errorFlag == 1
    "     let result = 'ERROR: Invalid Input' 
    " endif

    return result
endfunction

"==========================================================================}}}
" s:OctaveEval
" Evaluates and expression using a systems Octave installation
" removes 'ans =' and trailing newline
" Errors in octave evaluation are thrown 
"=============================================================================
function! s:OctaveEval(expression)
    let expression = a:expression

    let result = system('octave --quiet --norc', expression)

    let result = substitute(result, "\s*\n$", '' , 'g')
    call s:PrintDebugMessage('[' . result . ']= expression after newline removed')

    try
        if matchstr(result, '^error:') != ''
        throw "Calc " . result 
        endif
    endtry

    let result = substitute(result, 'ans =\s*', '' , 'g')
    call s:PrintDebugMessage('[' . result . ']= expression after ans removed')


    return result
endfunction

"==========================================================================}}}
" crunch#EvalTypes
" returns the possible evaluation types for Crunch 
"=============================================================================
function! crunch#EvalTypes(ArgLead, CmdLine, CursorPos)
    let s:evalTypes = [ 'Octave',  'VimScript' ]
    return s:evalTypes
endfunction

"==========================================================================}}}
" crunch#ChooseEval()
" returns the possible evaluation types for Crunch 
"=============================================================================
function! crunch#ChooseEval(EvalSource)

    let s:crunch_using_octave = 0
    let s:crunch_using_vimscript = 0

    if a:EvalSource == 'VimScript'
        let s:crunch_using_vimscript = 1
    elseif a:EvalSource == 'Octave' 
        let s:crunch_using_octave = 1
    else
        Throw 'Crunch error: "'. a:EvalSource . '" is an invalid evaluation source, Defaulting to VimScript"
        let s:crunch_using_vimscript = 1
    endif

endfunction


function! Throw(text)
    throw a:text
endfunction
