"=============================================================================
"Header                                                                    {{{
"=============================================================================
"A cross platform compatible (Windows/Linux/OSX) plugin that facilitates
"entering a search terms and opening web browsers 
"Last Change: 25 Jul 2013
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
" The Top Level Function that determines  program flow
"=============================================================================
let g:crunch_tag_marker = '#' 
let g:crunch_calc_prompt = 'Calc >> '
let g:crunch_calc_comment = '"'

"=============================================================================
"crunch_debug enables varies echos throughout the code                                                                              
"=============================================================================
let s:crunch_debug = 1

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
    if s:ValidLine(OriginalExpression) == 0 | return | endif
    let OriginalExpression = s:RemoveOldResult(OriginalExpression)
    let expression = s:ReplaceTag(OriginalExpression)
    if s:crunch_debug | echo '[' OriginalExpression . '] is the OriginalExpression' | endif
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

    " convert ints to floats
    let expression = substitute(expression, '\(\d\+\(\.\d\+\)\=\)', '\=str2float(submatch(0))' , 'g')
    if s:crunch_debug | echom '[' . expression . '] = is the expression converted to floats' | endif

    " let expression = tolower(expression) "makes user defined function not work 
    " let expression = s:RemoveSpaces(expression)
    let expression = s:FixMultiplication(expression)
    "let finalExpression = s:HandleCarrot(expression)
    return expression
endfunction

"==========================================================================}}}
"s:ValidLine                                                               {{{
"Checks the line to see if it is a variable definition, or a blank line that
"may or may not contain whitespace. 

"If the line is invalid this function returns false
"=============================================================================
function! s:ValidLine(expression) 
    let result = 1

    if a:expression == '' | let result = 0 | endif "checks for blank lines
    if matchstr(a:expression, "^\s*" . g:crunch_calc_comment . ".*$") !=''  | let result = 0 | endif "checks for commented lines

    if s:crunch_debug | echom '[' . a:expression . '] = the tested string' | endif
    if s:crunch_debug | echom '[' .  matchstr(a:expression, "^\s*" . g:crunch_calc_comment . ".*$") . "] = the matched string & result =" . result |  endif

    if matchstr(a:expression, "^*\s$") !=''  | let result = 0 | endif " checks for empty lines
    if s:crunch_debug | echom '[' . a:expression . '] = the tested string' | endif
    if s:crunch_debug | echom '[' .  matchstr(a:expression, '.\+#\s\+=\s\+.\+') . "] = the matched string cool guy" |  endif
    let test = matchstr(a:expression, '.\+' . g:crunch_tag_marker . '\s\+=\s\+.\+') " checks for tag lines
    if test !='' | let result = 0 | endif
    return result
endfunction

"==========================================================================}}}
"s:ReplaceTag                                                              {{{
"Replaces the tag within an expression with the value of that tag
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
"Searches for the value of a tag and returns the value assigned to the tag
"TODO give the source  this script
"=============================================================================
function! s:GetTagValue(tag)
    let s = search( '^'. a:tag . g:crunch_tag_marker, "bn" )
    if s == 0 | throw "Calc error: tag ".tag." not found" | endif
    " avoid substitute() as we are called from inside substitute()
    let line = getline( s )
    let idx = strridx( line, "=" )
    if idx == -1 |  throw "Calc error: line with tag ".tag."doesn't contain the '='" | endif
    let tagvalue= strpart( line, idx+1 )
    if s:crunch_debug | echom "[" . tagvalue . "] = the tag value" | endif
    return tagvalue
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
    "TODO deal with )( -> )*(
    let s:e = substitute(a:expression,'\()\)\s*\((\)', '\1\*\2','g')
    if s:crunch_debug | echom s:e . "= fixed multiplication 1" | endif
    "TODO deal with sin(1)sin(1)
    let s:e = substitute(s:e,'\()\)\s*\(\a\+\)', '\1\*\2','g')
    if s:crunch_debug | echom s:e . "= fixed multiplication 2" | endif
    "deal with 5sin( -> 5*sin(
    " '\(\d\+\(\.\d\+\)\=\)'
    let s:e = substitute(s:e,'\([0-9.]\+\)\s*\(\a\+\)', '\1\*\2','g')
    if s:crunch_debug | echom s:e . "= fixed multiplication 3" | endif
    "deal with )5 -> )*5
    let s:e = substitute(s:e, '\()\)\s*\(\d*\.\{0,1}\d\+\)', '\1\*\2', 'g')
    if s:crunch_debug | echom s:e . "= fixed multiplication 4" | endif
    "deal with 5( -> 5*(
    let s:e = substitute(s:e, '\([0-9.]\+\)\s*\((\)', '\1\*\2', 'g')
    if s:crunch_debug | echom s:e . "= fixed multiplication 5" | endif
    return s:e
endfunction

"==========================================================================}}}
" s:EvaluateExpression                                                     {{{
" Evaluates the expression and checks for errors in the process. Also 
" if there is no error echo the result and save a copy of it to the default 
" paste register
"=============================================================================
function! s:EvaluateExpression(expression)
    if s:crunch_debug | echom a:expression . " this tis the final expression" | endif
    let errorFlag = 0
    " try
    let result = string(eval(a:expression))
    if s:crunch_debug | echo '[' . matchstr(result,"\\.0$") . '] is the matched string' | endif
    if matchstr(result,"\\.0$") == ".0"  "matches  the 10 in 8e10 for some reason 
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
    let @" = result
endif
return result
endfunction

"==========================================================================}}}
" s:EvaluateExpressionLine                                                 {{{
" Evaluates the expression and checks for errors in the process. Also 
" if there is no error echo the result and save a copy of it to the default 
" pase register
"=============================================================================
function! s:EvaluateExpressionLine(expression)
    if s:crunch_debug |     echom a:expression  " this this the final expression" | endif
    let errorFlag = 0
    echom a:expression
    " try
    let result = string(eval(a:expression))
    if s:crunch_debug | echo '[' . matchstr(result,"\\.0$") . '] is the matched string' | endif
    if s:crunch_debug | echom result  " this this the final result before intization" | endif
    if matchstr(result,"\\.0$") == ".0"  "had to use \m for normal magicness for some reason
        if s:crunch_debug | echo '[' . matchstr(result,"\.0$") . '] is the matched string' | endif
        "TODO? add in printf for large nums that would eval to e numbers
        let result = string(str2nr(result))
        if s:crunch_debug | echom result  " this this the final result after intization" | endif
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
" Commands                                                                 {{{
"=============================================================================

if !hasmapto(':Crunch')
    command! -nargs=* -range=% Crunch call s:Crunch()
endif

if !hasmapto(':CrunchLine')
    command! -nargs=* -range CrunchLine <line1>,<line2>call s:CrunchLine('.') "send the current line
endif

nnoremap <silent> <unique> <Plug>Crunch_Line :call <SID>CrunchLine('.')<CR>

