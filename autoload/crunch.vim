""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Original Author: Ryan Carney
" License: WTFPL
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" BOILER PLATE {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:save_cpo = &cpo
set cpo&vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" GLOBALS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Holds the variables captured in a range/selection
let s:variables = {}

let s:valid_variable = '\v[a-zA-Z_]+[a-zA-Z0-9_]*'

" Number Regex Patterns
let sign = '\v[-+]?'
let number = '\v\.\d+|\d+%([.]\d+)?'
let e_notation = '\v%([eE][+-]?\d+)?'
let s:num_pat = sign . '%(' . number . e_notation . ')'

let s:error_tag = 'Crunch error: '
let s:is_exclusive = 0
let s:bang = ''
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" PUBLIC FUNCTIONS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#cmd_line_crunch(user_input) "{{{2
    " If there is no user input prompts the user for it, then evaluate the
    " input as a mathematical expression, display the result as well as
    " copying it to the user's clipboard

    if a:user_input != ''
        let expr = a:user_input
    else
        let expr = s:get_user_input()
        redraw
    endif

    try
        if s:valid_line(expr) == 0 | return | endif
        let result = crunch#core(expr)

        echomsg expr." = ".result

        "TODO make this optional
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
        call s:echo_error(v:exception)
    endtry
endfunction "}}}2


function! crunch#eval(exprs) abort "{{{2
    " Takes string of mathematical expressions delimited by new lines
    " evaluates "each line individually while saving variables when they occur

    call util#debug#print_header('Inizilation')
    let s:variables = g:crunch_user_variables

    let expr_list = split(a:exprs, '\n', 1)
    call util#debug#print_var_msg(string(expr_list), 'List of expr')

    for i in range(len(expr_list))
        try
            let orig_line = expr_list[i]
            let expr_list[i] = s:crunch_init(expr_list[i])
            call s:capture_variable(expr_list[i])

            if s:valid_line(expr_list[i]) == 0
                let expr_list[i] = orig_line
                continue
            endif

            " preserve the expression without an old result
            let expr_list[i] = s:remove_old_result(expr_list[i])
            let orig_expr = expr_list[i]

            let expr_list[i] = s:mark_e_notation(expr_list[i])
            let expr_list[i] = s:replace_captured_variable(expr_list[i])
            let expr_list[i] = s:replace_variable2(expr_list[i], i)
            let expr_list[i] = s:unmark_e_notation(expr_list[i])
            let result  = crunch#core(expr_list[i])
        catch /Crunch error: /
            call s:echo_error(v:exception)
            let result= v:exception
        endtry
        let expr_list[i] = s:build_result(orig_expr, result)
    endfor
    call util#debug#print_msg(string(expr_list).'= the expr_lines_list')
    let expr_lines = join(expr_list, "\n")
    call util#debug#print_msg(string(expr_lines).'= the expr_lines')
    let s:variables = {}
    return expr_lines
endfunction "}}}2


function! crunch#command(count, first_line, last_line, cmd_input, bang) abort "{{{2
    " The top level function that handles arguments and user input

    let cmd_input_expr  = s:handle_cmd_input(a:cmd_input, a:bang)

    if cmd_input_expr != '' "an expression was passed in
        "TODO only call this once if possible 03 May 2014
        call crunch#cmd_line_crunch(cmd_input_expr)
    else "no command was passed in

        try
            let s:selection = selection#new(a:count, a:first_line, a:last_line)
        catch
            call s:throw('Please install selection.vim for this operation')
        endtry

        if s:selection.content == '' "no lines or Selection was returned
            call crunch#cmd_line_crunch(s:selection.content)
        else
            call s:selection.over_write(crunch#eval(s:selection.content))
        endif
    endif
    let s:bang = '' "TODO refactor
endfunction "}}}2


function! crunch#core(expression) "{{{2
    " The core functionality of crunch

    let expr = s:fix_multiplication(a:expression)
    let expr = s:integer_to_float(expr)
    let expr = s:add_leading_zero(expr)
    return s:eval_math(expr)
endfunction "}}}2


function! crunch#operator(type) "{{{2

    call util#debug#print_header('Operator')
    "backup settings that we will change
    let sel_save = &selection
    let cb_save = &clipboard

    "make selection and clipboard work the way we need
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus

    "backup the unnamed register, which we will be yanking into
    let reg_save = @@

    call util#debug#print_var_msg(string(a:type), 'Operator Selection Type')
    "yank the relevant text, and also set the visual selection (which will be reused if the text
    "needs to be replaced)
    if a:type =~ '^\d\+$'
        "if type is a number, then select that many lines
        silent exe 'normal! V'.a:type.'$y'

    elseif a:type =~ '^.$'
        "if type is 'v', 'V', or '<C-V>' (i.e. 0x16) then reselect the visual region
        silent exe "normal! `<" . a:type . "`>y"
        call util#debug#print_msg('catch all type')
        let type=a:type

    elseif a:type == 'block'
        "block-based text motion
        silent exe "normal! `[\<C-V>`]y"
        call util#debug#print_msg('block type')
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
    call util#debug#print_var_msg(regtype, "the regtype")
    let repl = crunch#eval(@@)

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
    let @@ = reg_save
    let &selection = sel_save
    let &clipboard = cb_save
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" INITIALIZATION {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:crunch_init(expr) "{{{2
    " Gets the expression from current line, builds the suffix/prefix regex if
    " need, and  removes the suffix and prefix from the expression

    call util#debug#print_header('Crunch Inizilation Debug')

    let expr = a:expr

    if !exists('b:filetype') || &filetype !=# b:filetype
        let b:filetype = &filetype
        call util#debug#print_msg('filetype set, rebuilding prefix/suffix regex')
        call util#debug#print_msg('['.&filetype.']= filetype')
        call s:build_prefix_and_suffix_regex()
    endif

    let s:prefix = matchstr(expr, b:prefix_regex)
    call util#debug#print_var_msg(s:prefix, "s:prefix")
    call util#debug#print_var_msg(b:prefix_regex, "prefix regex")

    let s:suffix = matchstr(expr, b:suffix_regex)
    call util#debug#print_var_msg(s:suffix, "s:suffix")
    call util#debug#print_var_msg(b:suffix_regex, "suffix regex")

    let expr = s:remove_prefix_n_suffix(expr)

    return expr
endfunction "}}}2


function! s:handle_cmd_input(cmd_input, bang) "{{{2
    " test if there is an arg in the correct form.
    " return the arg if it's valid otherwise an empty string is returned

    call util#debug#print_header('Handle Args')
    call util#debug#print_var_msg(a:cmd_input,'the cmd_input')

    "was there a bang after the command?
    let s:bang = a:bang

    "find command switches in the expression and extract them into a list
    let options = split(matchstr(a:cmd_input, '\v^\s*(-\a+\ze\s+)+'), '\v\s+-')
    call util#debug#print_var_msg(string(options),'the options')

    "remove the command switches from the cmd_input
    let expr = substitute(a:cmd_input, '\v\s*(-\a+\s+)+', '', 'g')
    call util#debug#print_var_msg(expr,'the commandline expr')

    return expr
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" FORMAT EXPRESSION{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:valid_line(expr) "{{{2
    " Checks the line to see if it is a variable definition, or a blank line
    " that may or may not contain whitespace. If the line is invalid this
    " function returns false

    call util#debug#print_header('Valid Line')
    call util#debug#print_msg('[' . a:expr . ']= the tested string' )

    "checks for commented lines
    if a:expr =~ '\v^\s*'.g:crunch_comment
        call util#debug#print_msg('test1 failed comment')
        return 0
    endif

    "checks for empty/blank lines
    if a:expr =~ '\v^\s*$'
        call util#debug#print_msg('test2 failed blank line')
        return 0
    endif

    "checks for lines that don't need evaluation
    if a:expr =~ '\v\C^\s*'.s:valid_variable.'\s*\=\s*-?\s*'.s:num_pat.'\s*$'
        call util#debug#print_msg('test3 failed dosnt need evaluation')
        return 0
    endif
    call util#debug#print_msg('It is a valid line!')
    return 1
endfunction "}}}2


function! s:remove_old_result(expr) "{{{2
    " Remove old result if any
    " eg '5+5 = 10' becomes '5+5'
    " eg 'var1 = 5+5 =10' becomes 'var1 = 5+5'
    " inspired by Ihar Filipau's inline calculator

    call util#debug#print_header('Remove Old Result')

    let expr = a:expr
    "if it's a variable declaration with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
    call util#debug#print_msg('[' . expr . ']= expression before removed result')

    let expr = substitute(expr, '\v\s*\=\s*('.s:num_pat.')?\s*$', "", "")
    call util#debug#print_msg('[' . expr . ']= after removed old result')

    let expr = substitute(expr, '\v\s*\=\s*Crunch error:.*\s*$', "", "")
    call util#debug#print_msg('[' . expr . ']= after removed old error')

    let expr = substitute(expr, '\v^\s\+\ze?.', "", "")
    call util#debug#print_msg('[' . expr . ']= after removed whitespace')

    let expr = substitute(expr, '\v.\zs\s+$', "", "")
    call util#debug#print_msg('[' . expr . ']= after removed whitespace')

    return expr
endfunction "}}}2


function! s:fix_multiplication(expr) "{{{2
    " turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'

    call util#debug#print_header('Fix Multiplication')

    "deal with ')( -> )*(', ')5 -> )*5' and 'sin(1)sin(1)'
    let expr = substitute(a:expr,'\v(\))\s*([(\.[:alnum:]])', '\1\*\2','g')
    call util#debug#print_msg('[' . expr . ']= fixed multiplication 1')

    "deal with '5sin( -> 5*sin(', '5( -> 5*( ', and  '5x -> 5*x'
    let expr = substitute(expr,'\v(\d)\s*([(a-df-zA-DF-Z])', '\1\*\2','g')
    call util#debug#print_msg('[' . expr . ']= fixed multiplication 2')

    return expr
endfunction "}}}2


function! s:integer_to_float(expr) "{{{2
    " Convert Integers in the exprs to floats by calling a substitute
    " command
    " NOTE: from HowMuch.vim

    call util#debug#print_header('Integer to Float')
    call util#debug#print_msg('['.a:expr.']= before int to float conversion')
    let expr = a:expr
    let expr = substitute(expr,'\(^\|[^.0-9]\)\zs\([eE]-\?\)\@<!\d\+\ze\([^.0-9]\|$\)', '&.0', 'g')
    call util#debug#print_msg('['.expr.']= after int to float conversion')
    return expr
endfunction "}}}2


" E NOTATION {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:mark_e_notation(expr) "{{{3
    " e.g
    " 5e3  -> 5#3
    " 5e-3 -> 5#-3

    let expr = a:expr
    let number = '\v(\.\d+|\d+([.]\d+)?)\zs[eE]\ze[+-]?\d+'
    let expr = substitute(expr, number, '#', 'g')
    return expr
endfunction  "}}}3


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:unmark_e_notation(expr) "{{{3
    " e.g
    " 5#3  -> 5e3
    " 5#-3 -> 5e-3

    let expr = a:expr
    call util#debug#print_var_msg(expr, 'before Unmarking E notation')
    "put back the e and remove the following ".0"
    let expr = substitute(expr, '\v#([-]?\d+)(\.0)?', 'e\1', 'g')
    call util#debug#print_var_msg(expr, 'after Unmarking E notation')
    return expr
endfunction! "}}}3
" }}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" HANDLE VARIABLES {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:capture_variable(expr) "{{{2

    call util#debug#print_header('Capture Variable')

    let var_name_pat = '\v\C^\s*\zs'.s:valid_variable.'\ze\s*\=\s*'
    let var_value_pat = '\v\=\s*\zs-?\s*'.s:num_pat.'\ze\s*$'

    let var_name = matchstr(a:expr, var_name_pat)
    let var_value = matchstr(a:expr, var_value_pat)

    call util#debug#print_var_msg(var_name, 'the name of the variable')
    call util#debug#print_var_msg(var_value, 'the value of the variable')

    if var_name != ''  && var_value != ''
        let s:variables[var_name] = '('.var_value.')'
        call util#debug#print_var_msg(string(s:variables), 'captured variables')
    endif
endfunction "}}}2


function! s:replace_captured_variable(expr) "{{{2

    call util#debug#print_header('Replace Captured Variablee')

    let expr = a:expr
    call util#debug#print_msg("[".expr."]= expression before variable replacement ")

    "strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:valid_variable.'\s*\=\s*', "", "")
    call util#debug#print_msg("[".expr."]= expression striped of variable")

    let variable_regex = '\v('.s:valid_variable .'\v)\ze([^(a-zA-Z0-9_]|$)' "TODO move this up to the top
    "replace variable with it's value
    let expr = substitute(expr, variable_regex,
                \ '\=s:get_variable_value3(submatch(1))', 'g' )

    call util#debug#print_msg("[".expr."]= expression after variable replacement")
    return expr
endfunction "}}}2


function! s:replace_variable(expr) "{{{2
    " Replaces the variable within an expression with the value of that
    " variable inspired by Ihar Filipau's inline calculator

    call util#debug#print_header('Replace Variable')

    let expr = a:expr
    call util#debug#print_msg("[".expr."]= expression before variable replacement ")

    "strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:valid_variable.'\s*\=\s*', "", "")
    call util#debug#print_msg("[".expr."]= expression striped of variable")

    "replace variable with it's value
    let expr = substitute( expr, '\v('.s:valid_variable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:get_variable_value(submatch(1))', 'g' )

    call util#debug#print_msg("[".expr."]= expression after variable replacement")
    return expr
endfunction "}}}2


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:get_variable_value3(variable) abort

    let value = get(s:variables, a:variable, "not found")
    if value == "not found"
        "call s:throw("value for ".a:variable." not found")
        return a:variable
    endif

    return value
endfunction "}}}2


function! s:get_variable_value(variable) "{{{2

    call util#debug#print_header('Get Variable Value')
    call util#debug#print_msg("[".getline('.')."]= the current line")

    call util#debug#print_msg("[" . a:variable . "]= the variable")

    let search_line = search('\v\C^('.b:prefix_regex.
                \ ')?\V'.a:variable.'\v\s*\=\s*' , "bnW")

    call util#debug#print_msg("[".search_line."]= result of search for variable")
    if search_line == 0
        call s:throw("variable ".a:variable." not found")
    endif

    call util#debug#print_msg("[" .getline(search_line). "]= line with variable value")
    let line = s:remove_prefix_n_suffix(getline(search_line))
    call util#debug#print_header('Get Variable Value Contiuned')

    let variable_value = matchstr(line,'\v\=\s*\zs-?\s*'.s:num_pat.'\ze\s*$')
    call util#debug#print_msg("[" . variable_value . "]= the variable value")
    if variable_value == ''
        call s:throw('value for '.a:variable.' not found')
    endif

    return '('.variable_value.')'
endfunction "}}}2


function! s:replace_variable2(expr, num) "{{{2

    call util#debug#print_header('Replace Variable 2')

    let expr = a:expr
    call util#debug#print_msg("[".expr."]= expression before variable replacement ")

    "strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:valid_variable.'\s*\=\s*', "", "")
    call util#debug#print_msg("[".expr."]= expression striped of variable")

    "replace variable with it's value
    let expr = substitute( expr, '\v('.s:valid_variable.
                \'\v)\ze([^(a-zA-Z0-9_]|$)',
                \ '\=s:get_variable_value2(submatch(1), a:num)', 'g' )

    call util#debug#print_msg("[".expr."]= expression after variable replacement")
    return expr
endfunction "}}}2


function! s:get_variable_value2(variable, num) "{{{2

    call util#debug#print_msg("[".a:num."]= is the num")
    call util#debug#print_msg("[".a:variable."]= is the variable to be replaced")
    let search_line = search('\v\C^('.b:prefix_regex.')?\V'.a:variable.'\v\s*\=\s*',
                \"bnW" )

    call util#debug#print_msg("[".search_line."]= search line")

    let line = s:remove_prefix_n_suffix(getline(search_line))
    let variable_value = matchstr(line,'\v\=\s*\zs-?\s*'.s:num_pat.'\ze\s*$')
    call util#debug#print_msg("[" . variable_value . "]= the variable value")
    if variable_value == ''
        call s:throw("value for ".a:variable." not found")
    else
        return '('.variable_value.')'
    endif
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" RESULT HANDLING{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:build_result(expr, result) "{{{2

    let output = a:expr .' = '. a:result

    "capture variable results if they exists TODO refactor
    call s:capture_variable(output)

    "bang isn't used and type is not append result
    if (s:bang == '!' && g:crunch_result_type_append)
                \|| (s:bang == '' && !g:crunch_result_type_append)
        let output = a:result
    endif
    call util#debug#print_var_msg(s:prefix, "s:prefix")
    call util#debug#print_var_msg(s:suffix, "s:suffix")
    call util#debug#print_var_msg(output, "output")
    return s:prefix.output.s:suffix
endfunction "}}}2


function! s:add_leading_zero(expr) "{{{2
    " convert .5*.34 -> 0.5*0.34

    let expr = a:expr
    call util#debug#print_header('Add Leading Zero')
    call util#debug#print_msg('['.expr.']= before adding leading zero')
    let expr = substitute(expr,'\v(^|[^.0-9])\zs\.\ze([0-9])', '0&', 'g')
    call util#debug#print_msg('['.expr.']= after adding leading zero')
    return expr
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" PREFIX/SUFFIX {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:remove_prefix_n_suffix(expr) "{{{2
    " Removes the prefix and suffix from a string

    let expr = a:expr
    call util#debug#print_header('Remove Line Prefix and Suffix')

    call util#debug#print_msg('['.b:prefix_regex.']= the REGEX of the prefix')
    call util#debug#print_msg('['.b:suffix_regex.']= the REGEX of the suffix')
    call util#debug#print_msg('['.expr.']= expression BEFORE removing prefix/suffix')
    let expr = substitute(expr, b:prefix_regex, '', '')
    call util#debug#print_msg('['.expr.']= expression AFTER removing prefix')
    let expr = substitute(expr, b:suffix_regex, '', '')
    call util#debug#print_msg('['.expr.']= expression AFTER removing suffix')
    return expr
endfunction "}}}2


function! s:build_prefix_and_suffix_regex() "{{{2
    " from a list of suffixes builds a regex expression for all suffixes in the
    " list

    call util#debug#print_header('Build Line Prefix')
    call util#debug#print_msg( "[".&commentstring."]=  the comment string ")
    let s:comment_start = matchstr(&commentstring, '\v.+\ze\%s')
    let s:prefixs = ['*','//', s:comment_start]
    call filter (s:prefixs, "v:val != ''")
    call util#debug#print_var_msg(string(s:prefixs), "s:prefixs")
    let b:prefix_regex = join( map(copy(s:prefixs), 'escape(v:val, ''\/'')'), '\|')
    call util#debug#print_msg("[".b:prefix_regex."]= REGEX for the prefixes")
    let b:prefix_regex= '\V\^\s\*\('.b:prefix_regex.'\)\=\s\*\v'

    call util#debug#print_header('Build Line Suffix')
    call util#debug#print_msg( "[".&commentstring."]=  the comment string ")
    let s:comment_end = matchstr(&commentstring, '\v.+\%s\zs.*')
    let s:suffixs = ['//', s:comment_end]
    call filter (s:suffixs, "v:val != ''")
    call util#debug#print_var_msg(string(s:suffixs), "s:suffixs")
    let b:suffix_regex = join( map(copy(s:suffixs), 'escape(v:val, ''\/'')'), '\|')
    call util#debug#print_msg( "[".b:suffix_regex."]= REGEX for suffixes ")
    let b:suffix_regex= '\V\[^ ]\{-1,}\zs\s\*\(\('.b:suffix_regex.'\)\.\*\)\=\s\*\$\v'

    "NOTE: these regex is very non magic see :h \V
endfunction "}}}2


function! s:get_user_input() "{{{2
    " prompt the user for an expression

    call inputsave()
    let expr = input(g:crunch_prompt)
    call inputrestore()
    return expr
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" EVALUATION {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:eval_math(expr) "{{{2
    " Return Output
    " append result (option: Append)
    " replace result (option: Replace)
    " append result of Statistical operation (option: Statistic)
    " a function pointers to the eval method
    " if python
    " if octave
    " if vimscript

    let result = s:vim_eval(a:expr)
    return result
endfunction "}}}2


function! s:vim_eval(expr) "{{{2
    " Evaluates the expression and checks for errors in the process. Also
    " if there is no error echo the result and save a copy of it to the default
    " paste register

    call util#debug#print_header('Evaluate Expression')
    call util#debug#print_msg('[' . a:expr . "]= the final expression")

    let result = string(eval(a:expr))
    call util#debug#print_msg('['.result.']= before trailing ".0" removed')
    call util#debug#print_msg('['.matchstr(result,'\v\.0+$').']= trailing ".0"')

    "check for trailing '.0' in result and remove it (occurs with vim eval)
    if result =~ '\v\.0+$'
        let result = string(str2nr(result))
    endif

    return result
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" ERRORS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:echo_error(error_string) "{{{2

    echohl Warning_msg
    echomsg a:error_string
    echohl None
endfunction "}}}2


function!  s:throw(error_body) abort "{{{2

    let Error_msg = s:error_tag.a:error_body
    throw Error_msg
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" BOILER PLATE {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let &cpo = s:save_cpo
unlet s:save_cpo
" vim:foldmethod=marker
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}
