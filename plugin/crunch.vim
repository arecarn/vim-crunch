"s:Crunch                                                                     {{{
" The Top Level Function that determines  program flow
"===============================================================================
function! s:Crunch(firstln,lastln) 
    "execute "normal! mh"
    "execute "normal! 'h" 
    let expression = s:GetInput(a:firstln,a:lastln)
    if expression == 'q'
        return
    endif 
    let ListExpressionOne = s:ListifyExpression(expression)
    let ListExpressionTwo = s:FloatifyExpression(ListExpressionOne)
    let finalExpression = s:RepairExpression(ListExpressionOne,ListExpressionTwo)
    let finalExpression = tolower(finalExpression) "makes user defined function not work 
    let finalExpression = s:RemoveSpaces(finalExpression)
    let finalExpression = s:FixMultiplication(finalExpression)
    "let finalExpression = s:HandleCarrot(finalExpression)
    call s:EvaluateExpression(finalExpression)
endfunction

"============================================================================}}}
"s:GetInput                                                                  {{{
"gets input either though prompt or visual selection
"===============================================================================
function! s:GetInput(firstln, lastln)
    "echo a:firstln . ' =first line '
    "echo a:lastln . ' =last line '
    let visualmode = s:CheckForVisual(a:firstln, a:lastln)
    if visualmode == 'no'
        let expression = s:GetinputString()
    elseif visualmode == 'yes'
        let expression = s:GetVisualSelection()
        "echo expression
    elseif visualmode == 'tooMuch'
        return "q"
    endif 
    if expression == ''
        return "q"
    endif
    echo expression
    return expression
endfunction


"============================================================================}}}
" s:GetinputString                                                           {{{
" prompt the user for an expression
"===============================================================================
function! s:GetinputString()
    call inputsave()
    let Expression = input("Calc >> ")
    call inputrestore()
    "echo Expression
    return Expression
endfunction

"============================================================================}}}
" s:GetVisualSelection                                                       {{{
" credit Pete Rodding:
" http://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript 
"
" gets the visually selected text
"===============================================================================
function! s:GetVisualSelection()
    " Why is this not a built-in Vim script function?!
    let [lnum1, col1] = getpos("'<")[1:2]
    let [lnum2, col2] = getpos("'>")[1:2]
    let lines = getline(lnum1, lnum2)
    let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][col1 - 1:]
    return join(lines, "\n")
endfunction

"============================================================================}}}
" s:CheckForVisual                                                         {{{
" Checks to see if there is a vialual selection and limits it to 1 line 
"=============================================================================
function! s:CheckForVisual(firstln, lastln)
    let testvar = a:lastln-a:firstln +1
    let lines = line('$')
     "echo lines . ' = the lines in the file'
     "echo testvar . ' = the selected lines '
     if lines == 1
         echo "Warning visual selections don't work with 1 line buffers"
     endif 
    if testvar == lines
        return 'no'
        "NOTE: limit selected lines to 1
    elseif testvar > 1  "
        return 'tooMuch'
    else
        return 'yes'
    endif
endfunction

"==========================================================================}}}
" s:RemoveSpaces                                                           {{{
" prompt the user for an expression
"=============================================================================
function! s:RemoveSpaces(expression)
    let s:e = substitute(a:expression,'\s','','g')
    echo s:e 'removed whitespace'
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
"=============================================================================
function! s:HandleCarrot(expression)
    let s:e = substitute(a:expression,'\([0-9.]\+\)\^\([0-9.]\+\)', 'pow(\1,\2)','g') " good
    let s:e = substitute(s:e, '\(\a\+(.\{-})\)\^\([0-9.]\+\)', 'pow(\1,\2)','g') "questionable 
    let s:e = substitute(s:e, '\([0-9.]\+\)\^\(\a\+(.\{-})\)' , 'pow(\1,\2)','g') "good 
    let s:e = substitute(s:e, '\(\a\+(.\{-})\)\^\(\a\+(.\{-})\)' , 'pow(\1,\2)','g') "bad
    return s:e
endfunction
"==========================================================================}}}
" s:FixMultiplication                                                      {{{
" turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'
"=============================================================================
function! s:FixMultiplication(expression)
    let s:e = substitute(a:expression,'\(\d*\.\{0,1}\d\)\(\a\)', '\1\*\2','g')
    let s:e = substitute(s:e, '\()\)\(\d*\.\{0,1}\d\)', '\1\*\2', 'g')
    let s:e = substitute(s:e, '\([0-9.]\+\)\((\)', '\1\*\2', 'g')
    "echo s:e . '  = fixed muliplication'
    return s:e
endfunction
"============================================================================}}}
" s:ListifyExpression                                                        {{{
" makes the expression a list of by putting spaces around non numbers 
"===============================================================================
function! s:ListifyExpression(expression)
    "space everything but numbers. eg 3.43*-1299 becoms 3.43 * - .1299
    "Then the expression is split by it's spaces [ '3.43' , '*', '-', '.1299']
    let e = a:expression
    let e = substitute(e, '\([^0-9.]\)', ' \1 ', 'g')
    let expressionList = split(e, ' ')
    return expressionList
endfunction

"============================================================================}}}
" s:FloatifyExpression                                                       {{{
" convert all items in the list into their float equivilent 
"===============================================================================
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

"============================================================================}}}
" s:RepairExpression                                                         {{{
" Convert Non numbers from 0.0 back to their original value
"===============================================================================
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


"============================================================================}}}
" s:EvaluateExpression                                                       {{{
" Evaluates the expression and checks for errors in the process. Also 
" if there is no error echo the result and save a copy of it to the defualt 
" pase register
"===============================================================================
function! s:EvaluateExpression(expression)
    echo a:expression . " this tis the final expression"
    let errorFlag = 0
    try
        execute "let result =" . a:expression
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
endfunction

"============================================================================}}}
" Commands                                                                   {{{
"===============================================================================
command! -nargs=* -range=% Crunch call s:Crunch(<line1>,<line2>)

"Crunch Line maping
map <Plug>Crunch_Line ^v$:Crunch<CR>A=<ESC>p

"NOTE
"the following mapping works in a vimrc 
"nmap <leader>ee <Plug>Crunch_Line

" notes on making a vim plugin 
" source after every save 
"autocmd BufWritePost vcal.vim source ~/.vim/bundle/vcal/plugin/vcal.vim
"you could also run a particular function every time you save 
"
"
