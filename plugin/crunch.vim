"Globals                                                                   {{{
" The Top Level Function that determines  program flow
"=============================================================================
let g:crunch_tag_marker = '#' 
let g:crunch_calc_prompt = 'Calc >> '
"let g:crunch_load_default_mappings = 1

"==========================================================================}}}
"s:Crunch                                                                  {{{
" The Top Level Function that determines  program flow
"=============================================================================
function! s:Crunch() 
    let OriginalExpression = s:GetInputString()
    let expression = s:RemoveOldResult(OriginalExpression)
    let expression = s:Core(expression)
    let result = s:EvaluateExpression(expression)
endfunction

"==========================================================================}}}
"s:CrunchLine                                                              {{{
" The Top Level Function that determines  program flow
"=============================================================================
function! s:CrunchLine(line) 
    let OriginalExpression = getline(a:line)
    let OriginalExpression = s:RemoveOldResult(OriginalExpression)
    let expression = s:ReplaceTag(OriginalExpression)
    let expression = s:Core(expression)
    let resultStr = s:EvaluateExpressionLine(expression)
    call setline(a:line, OriginalExpression.' = '.resultStr)
endfunction

"==========================================================================}}}
"s:Core                                                                    {{{
"the main functionality of crunch
"=============================================================================
function! s:Core(e) 
    let expression = a:e
    let ListExpressionOne = s:ListifyExpression(expression)
    let ListExpressionTwo = s:FloatifyExpression(ListExpressionOne)
    let expression = s:RepairExpression(ListExpressionOne,ListExpressionTwo)
    let expression = tolower(expression) "makes user defined function not work 
    let expression = s:RemoveSpaces(expression)
    let expression = s:FixMultiplication(expression)
    "let finalExpression = s:HandleCarrot(expression)
    return expression
endfunction

"==========================================================================}}}
"s:ReplaceTag                                                              {{{
"TODO give the source of this script
"=============================================================================
function! s:ReplaceTag(expression) 
    let e = a:expression
    " strip the tag, if any
    let e = substitute( e, '[a-zA-Z0-9]\+' . g:crunch_tag_marker . '[[:space:]]*', "", "" )

    " replace values by the tag
    let e = substitute( e, g:crunch_tag_marker . '\([a-zA-Z0-9]\+\)', '\=s:GetTagValue(submatch(1))', 'g' )
    return e
endfunction

"==========================================================================}}}
"s:GetTagValue                                                             {{{
"TODO give the source  this script
"=============================================================================
function! s:GetTagValue(tag)
    let s = search( '^'. a:tag . g:crunch_tag_marker, "bn" )
    if s == 0 | throw "Calc error: tag ".tag." not found" | endif
    " avoid substitute() as we are called from inside substitute()
    let line = getline( s )
    let idx = strridx( line, "=" )
    if idx == -1 |  throw "Calc error: line with tag ".tag."doesn't contain the '='" | endif
    return strpart( line, idx+1 )
endfunction

"==========================================================================}}}
"s:RemoveOldResult                                                         {{{
"Remove old result if any eg '5+5 = 10' becomes '5+5'
"TODO give the source of this script
"=============================================================================
function! s:RemoveOldResult(expression)
    let e = a:expression
    let e = substitute( e, '[[:space:]]*=.*', "", "" )
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
    "echo Expression
    return Expression
endfunction

"==========================================================================}}}
" s:RemoveSpaces                                                           {{{
" prompt the user for an expression
"=============================================================================
function! s:RemoveSpaces(expression)
    let s:e = substitute(a:expression,'\s','','g')
    "echo s:e 'removed whitespace'
    return s:e
endfunction

"==========================================================================}}}
" s:HandleCarrot                                                           {{{
" changes '2^5' into 'pow(2,5)' 
" cases
" fun()^fun() eg sin(1)^sin(1)
" fun()^num() eg sin(1)^2
" num^fun() eg 2^sin(1) 
" num^num() eg 2^2
" NOTE: this is not implemented and is a work in progress
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
    "deal with 5sin( -> 5*sin(
    let s:e = substitute(a:expression,'\([0-9.]\+\)\(\a\+\)', '\1\*\2','g')
    "deal with )5 -> )*5
    let s:e = substitute(s:e, '\()\)\(\d*\.\{0,1}\d\)', '\1\*\2', 'g')
    "deal with 5( -> 5*(
    let s:e = substitute(s:e, '\([0-9.]\+\)\((\)', '\1\*\2', 'g')
    " echo s:e . '  = fixed muliplication'
    return s:e
endfunction

"==========================================================================}}}
" s:ListifyExpression                                                      {{{
" makes the expression a list of by putting spaces around non numbers 
"=============================================================================
function! s:ListifyExpression(expression)
    "space everything but numbers. eg 3.43*-1299 becoms 3.43 * - .1299
    "Then the expression is split by it's spaces [ '3.43' , '*', '-', '.1299']
    let e = a:expression
    let e = substitute(e, '\([^0-9.]\)', ' \1 ', 'g')
    let expressionList = split(e, ' ')
    return expressionList
endfunction

"==========================================================================}}}
" s:FloatifyExpression                                                     {{{
" convert all items in the list into their float equivilent 
"=============================================================================
function! s:FloatifyExpression(ListExpression)
    "convert every space delimneted value into a float 
    " E.G. [ '3.43', '*', '-', '.1299' ] becomes [ '3.43', '0.00', '0.00', '0.1299']
    let newexpressionList = []
    for bit in a:ListExpression
        call add(newexpressionList, string(str2float(bit)))
    endfor
    "echom string(newexpressionList)
    return newexpressionList
endfunction

"==========================================================================}}}
" s:RepairExpression                                                       {{{
" Convert Non numbers from 0.0 back to their original value
"=============================================================================
function! s:RepairExpression(OldListExpression, ListExpression)
    " if a non number evaluated to 0.0 replace it with it's old value 
    " Eg from the last example [ '3.43', '0.00', '0.00', '0.1299'] [ '3.43', '*', '-', '0.1299']
    " so loop through every part of the list
    let NewListExpression = a:ListExpression
    let index = len(a:ListExpression) - 1
    while index >= 0 
        if a:ListExpression[index] == "0.0"
            let NewListExpression[index] = a:OldListExpression[index]
        endif 
        let index = index - 1 
    endwhile
    "join the expression list and dertermine to output
    let expressionFinal=join(NewListExpression, '')
    "echo expressionFinal
    return expressionFinal
endfunction

"==========================================================================}}}
" s:EvaluateExpression                                                     {{{
" Evaluates the expression and checks for errors in the process. Also 
" if there is no error echo the result and save a copy of it to the defualt 
" pase register
"=============================================================================
function! s:EvaluateExpression(expression)
    " echo a:expression . " this tis the final expression"
    let errorFlag = 0
    try
        let result = eval(a:expression)
    catch /^Vim\%((\a\+)\)\=:E/	" catch all Vim errors
        let errorFlag = 1  
    endtry
    if errorFlag == 1
        echom "ERROR: invalid input"
        let @" = "ERROR: invalid input"
    else
        redraw
        echo a:expression
        echo "= " . string(result)
        echo "Yanked Result"
        let @" = string(result)
    endif
    return result
endfunction

"==========================================================================}}}
" s:EvaluateExpressionLine                                                 {{{
" Evaluates the expression and checks for errors in the process. Also 
" if there is no error echo the result and save a copy of it to the defualt 
" pase register
"=============================================================================
function! s:EvaluateExpressionLine(expression)
    " echo a:expression . " this tis the final expression"
    let errorFlag = 0
    try
        let result = string(eval(a:expression))
    catch /^Vim\%((\a\+)\)\=:E/	"catch all Vim errors
        let errorFlag = 1  
    endtry
    if errorFlag == 1
        let result = 'ERROR: Invalid Input' 
    endif
    return result
endfunction

"==========================================================================}}}
" Commands                                                                 {{{
"=============================================================================
command! -nargs=* -range=% Crunch call s:Crunch()

command! -nargs=* -range=% CrunchLine call s:CrunchLine('.') "send the current line

