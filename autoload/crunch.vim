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
let s:variable_regex = '\v('.s:valid_variable.'\v)\ze([^(a-zA-Z0-9_]|$)'

" Number Regex Patterns
let sign = '\v[-+]?'
let number = '\v\.\d+|\d+%([.]\d+)?'
let e_notation = '\v%([eE][+-]?\d+)?'
let s:num_pat = sign . '%(' . number . e_notation . ')'

let s:error_tag = 'Crunch error: '
let s:is_exclusive = 0
let s:bang = ''

let s:input_type = ''
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" PUBLIC FUNCTIONS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! crunch#cmd_line_crunch(user_input) abort "{{{2
    " If there is no user input prompts the user for it, then evaluate the
    " input as a mathematical expression, display the result as well as
    " copying it to the user's clipboard

    if a:user_input !=# ''
        let expr = a:user_input
    else
        let expr = s:get_user_input()
        redraw
    endif

    try
        if s:valid_line(expr) == 0 | return | endif
        let result = crunch#core(expr)

        echomsg expr.' = '.result

        "TODO make this optional
        if has('clipboard')
            echo 'Yanked Result'
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

"    Decho '== Inizilation =='
    let s:variables = deepcopy(g:crunch_user_variables, 0)

    let expr_list = split(a:exprs, '\n', 1)
"    Decho 'expr_list = <'.string(expr_list).'>'

    for i in range(len(expr_list))
        try
            let orig_line = expr_list[i]
            let expr_list[i] = s:crunch_init(expr_list[i])

            if s:valid_line(expr_list[i]) == 0
                call s:capture_variable(expr_list[i])
                let expr_list[i] = orig_line
                continue
            endif

            " preserve the expression without an old result
            let expr_list[i] = s:remove_old_result(expr_list[i])
            let orig_expr = expr_list[i]

            let expr_list[i] = s:mark_e_notation(expr_list[i])
            let expr_list[i] = s:replace_captured_variable_with_value(expr_list[i])
            let expr_list[i] = s:replace_searched_variable_with_value(expr_list[i])
            let expr_list[i] = s:unmark_e_notation(expr_list[i])
            let result  = crunch#core(expr_list[i])
        catch /Crunch error: /
            call s:echo_error(v:exception)
            let result= v:exception
        endtry
        let expr_list[i] = s:build_result(orig_expr, result)
    endfor
"    Decho string(expr_list).'= the expr_lines_list'
    let expr_lines = join(expr_list, "\n")
"    Decho expr_lines.'= the expr_lines'
    let s:variables = {}
    return expr_lines
endfunction "}}}2


function! crunch#command(count, first_line, last_line, cmd_input, bang) abort "{{{2
    " The top level function that handles arguments and user input

    let s:input_type = ''
    let cmd_input_expr  = s:handle_cmd_input(a:cmd_input, a:bang)

    if cmd_input_expr !=# '' "an expression was passed in
        "TODO only call this once if possible 03 May 2014
        call crunch#cmd_line_crunch(cmd_input_expr)
    else "no command was passed in

        try
            let s:selection = selection#new(a:count, a:first_line, a:last_line)
        catch /^Vim\%((\a\+)\)\=:E117/  " catch error E117: Unknown function
            call s:throw('Please install selection.vim for this operation')
        endtry

        if s:selection.content ==# '' "no lines or Selection was returned
            call crunch#cmd_line_crunch(s:selection.content)
        else
            if s:selection.type ==# 'lines'
                let s:input_type = 'linewise'
            endif
            call s:selection.over_write(crunch#eval(s:selection.content))
        endif
    endif
    let s:bang = '' "TODO refactor
endfunction "}}}2


function! crunch#core(expression) abort "{{{2
    " The core functionality of crunch

    let expr = s:fix_multiplication(a:expression)
    let expr = s:integer_to_float(expr)
    let expr = s:add_leading_zero(expr)
    return s:eval_math(expr)
endfunction "}}}2

function! crunch#linewise_operator() abort
    let s:input_type = 'linewise'
endfunction

function! crunch#normal_operator() abort
    let s:input_type = ''
endfunction

function! crunch#visual_operator() abort
    let s:input_type = ''
endfunction


function! crunch#operator(type) abort "{{{2

"    Decho '== Operator =='
    "backup settings that we will change
    let sel_save = &selection
    let cb_save = &clipboard

    "make selection and clipboard work the way we need
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus

    "backup the unnamed register, which we will be yanking into
    let reg_save = @@

"    Decho 'a:type = <'.a:type.'>'
    "yank the relevant text, and also set the visual selection (which will be reused if the text
    "needs to be replaced)
    if a:type =~# '^.$'
        "if type is 'v', 'V', or '<C-V>' (i.e. 0x16) then reselect the visual region
        silent execute 'normal! `<' . a:type . '`>y'
"        Decho 'catch all type'
        let type=a:type

        if a:type ==# 'V'
            call crunch#linewise_operator()
        endif

    elseif a:type ==# 'block'
        "block-based text motion
        silent execute 'normal! `[\<C-V>`]y'
"        Decho 'block type'
        let type="\<C-V>"

    elseif a:type ==# 'line'
        "line-based text motion
        silent execute 'normal! `[V`]y'
        let type='V'
        call crunch#linewise_operator()

    else
        "char-based text motion
        silent execute 'normal! `[v`]y'
        let type='v'
    endif

    let regtype = type

"    Decho 'regtype = <'.regtype.'>'
    let repl = crunch#eval(@@)

    "if the function returned a value, then replace the text
    if type(repl) == 1
        "put the replacement text into the unnamed register, and also set it to be a
        "characterwise, linewise, or blockwise selection, based upon the selection type of the
        "yank we did above
        call setreg('@', repl, regtype)
        "reselect the visual region and paste
        normal! gvp
        execute "normal! gvo\<Esc>"
    endif

    "restore saved settings and register value
    let @@ = reg_save
    let &selection = sel_save
    let &clipboard = cb_save
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" INITIALIZATION {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:crunch_init(expr) abort "{{{2
    " Gets the expression from current line, builds the suffix/prefix regex if
    " need, and  removes the suffix and prefix from the expression

"    Decho '== Crunch Inizilation Debug =='

    let expr = a:expr

    if !exists('b:filetype') || &filetype !=# b:filetype
        let b:filetype = &filetype
"        Decho 'filetype set, rebuilding prefix/suffix regex'
"        Decho '['.&filetype.']= filetype'
        call s:build_prefix_and_suffix_regex()
    endif

    let s:prefix = matchstr(expr, b:prefix_regex)
    let prefix = s:prefix
"    Decho 'prefix = <'.string(prefix).'>'
    let prefix_regex = b:prefix_regex
"    Decho 'prefix_regex = <'.string(prefix_regex).'>'

    let s:suffix = matchstr(expr, b:suffix_regex)
    let suffix = s:suffix
"    Decho 'suffix = <'.string(suffix).'>'
    let suffix_regex = b:suffix_regex
"    Decho 'suffix_regex = <'.string(suffix_regex).'>'

    let expr = s:remove_prefix_n_suffix(expr)

    return expr
endfunction "}}}2


function! s:handle_cmd_input(cmd_input, bang) abort "{{{2
    " test if there is an arg in the correct form.
    " return the arg if it's valid otherwise an empty string is returned

"    Decho '== Handle Args =='
"    Decho 'a:cmd_input = <'.string(a:cmd_input).'>'

    "was there a bang after the command?
    let s:bang = a:bang

    "find command switches in the expression and extract them into a list
    let options = split(matchstr(a:cmd_input, '\v^\s*(-\a+\ze\s+)+'), '\v\s+-')
"    Decho 'options = <'.string(options).'>'

    "remove the command switches from the cmd_input
    let expr = substitute(a:cmd_input, '\v\s*(-\a+\s+)+', '', 'g')
"    Decho 'expr = <'.string(expr).'>'

    return expr
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" FORMAT EXPRESSION{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:valid_line(expr) abort "{{{2
    " Checks the line to see if it is a variable definition, or a blank line
    " that may or may not contain whitespace. If the line is invalid this
    " function returns false

"    Decho '== Valid Line =='
"    Decho '[' . a:expr . ']= the tested string'

    "checks for commented lines
    if a:expr =~# '\v^\s*'.g:crunch_comment
"        Decho 'test1 failed comment'
        return 0
    endif

    "checks for empty/blank lines
    if a:expr =~# '\v^\s*$'
"        Decho 'test2 failed blank line'
        return 0
    endif

    "checks for lines that don't need evaluation
    if a:expr =~# '\v\C^\s*'.s:valid_variable.'\s*\=\s*-?\s*'.s:num_pat.'\s*$'
"        Decho 'test3 failed dosnt need evaluation'
        return 0
    endif
"    Decho 'It is a valid line!'
    return 1
endfunction "}}}2


function! s:remove_old_result(expr) abort "{{{2
    " Remove old result if any
    " eg '5+5 = 10' becomes '5+5'
    " eg 'var1 = 5+5 =10' becomes 'var1 = 5+5'
    " inspired by Ihar Filipau's inline calculator

"    Decho '== Remove Old Result =='

    let expr = a:expr
    "if it's a variable declaration with an expression ignore the first = sign
    "else if it's just a normal expression just remove it
"    Decho '[' . expr . ']= expression before removed result'

    let expr = substitute(expr, '\v\s*\=\s*('.s:num_pat.')?\s*$', '', '')
"    Decho '[' . expr . ']= after removed old result'

    let expr = substitute(expr, '\v\s*\=\s*Crunch error:.*\s*$', '', '')
"    Decho '[' . expr . ']= after removed old error'

    let expr = substitute(expr, '\v^\s\+\ze?.', '', '')
"    Decho '[' . expr . ']= after removed whitespace'

    let expr = substitute(expr, '\v.\zs\s+$', '', '')
"    Decho '[' . expr . ']= after removed whitespace'

    return expr
endfunction "}}}2


function! s:fix_multiplication(expr) abort "{{{2
    " turns '2sin(5)3.5(2)' into '2*sing(5)*3.5*(2)'

"    Decho '== Fix Multiplication =='

    "deal with ')( -> )*(', ')5 -> )*5' and 'sin(1)sin(1)'
    let expr = substitute(a:expr,'\v(\))\s*([(\.[:alnum:]])', '\1\*\2','g')
"    Decho '[' . expr . ']= fixed multiplication 1'

    "deal with '5sin( -> 5*sin(', '5( -> 5*( ', and  '5x -> 5*x'
    let expr = substitute(expr,'\v(\d)\s*([(a-df-zA-DF-Z])', '\1\*\2','g')
"    Decho '[' . expr . ']= fixed multiplication 2'

    return expr
endfunction "}}}2


function! s:integer_to_float(expr) abort "{{{2
    " Convert Integers in the exprs to floats by calling a substitute
    " command
    " NOTE: from HowMuch.vim

"    Decho '== Integer to Float =='
"    Decho '['.a:expr.']= before int to float conversion'
    let expr = a:expr
    let expr = substitute(expr,'\(^\|[^.0-9]\)\zs\([eE]-\?\)\@<!\d\+\ze\([^.0-9]\|$\)', '&.0', 'g')
"    Decho '['.expr.']= after int to float conversion'
    return expr
endfunction "}}}2


" E NOTATION {{{2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:mark_e_notation(expr) abort "{{{3
"    Decho '== Mark E Notation =='
    " e.g
    " 5e3  -> 5#3
    " 5e-3 -> 5#-3

    let expr = a:expr
    let number = '\v(\.\d+|\d+([.]\d+)?)\zs[eE]\ze[+-]?\d+'
    let expr = substitute(expr, number, '#', 'g')
"    Decho 'expr = <'.expr.'>'
    return expr
endfunction  "}}}3


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:unmark_e_notation(expr) abort "{{{3
"    Decho '== Unmark E Notation =='
    " e.g
    " 5#3  -> 5e3
    " 5#-3 -> 5e-3

    let expr = a:expr
"    Decho 'expr = <'.expr.'>'
    "put back the e and remove the following '.0'
    let expr = substitute(expr, '\v#([-]?\d+)(\.0)?', 'e\1', 'g')
"    Decho 'expr = <'.expr.'>'
    return expr
endfunction "}}}3
" }}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" HANDLE VARIABLES {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:capture_variable(expr) abort "{{{2

"    Decho '== Capture Variable =='

    let var_name_pat = '\v\C^\s*\zs'.s:valid_variable.'\ze\s*\=\s*'
    let var_value_pat = '\v\=\s*\zs-?\s*'.s:num_pat.'\ze\s*$'

    let var_name = matchstr(a:expr, var_name_pat)
    let var_value = matchstr(a:expr, var_value_pat)

"    Decho 'var_name = <'.string(var_name).'>'
"    Decho 'var_value = <'.string(var_value).'>'

    if var_name !=# ''  && var_value !=# ''
        let s:variables[var_name] = '('.var_value.')'
        let variables = s:variables
"        Decho 'variables = <'.string(variables).'>'
    endif
endfunction "}}}2


function! s:replace_captured_variable_with_value(expr) abort "{{{2

"    Decho '== Replace Captured Variablee =='

    let expr = a:expr
"    Decho '['.expr.']= expression before variable replacement'

    let expr = s:mark_e_notation(expr)
    "strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:valid_variable.'\s*\=\s*', '', '')
"    Decho '['.expr.']= expression striped of variable'

    "replace variable with it's value
    let expr = substitute(
                \ expr,
                \ s:variable_regex,
                \ '\=s:get_captured_variable_value(submatch(1))', 'g')
    let expr = s:mark_e_notation(expr)

    let expr = s:unmark_e_notation(expr)
"    Decho '['.expr.']= expression after variable replacement'
    return expr
endfunction "}}}2


function! s:get_captured_variable_value(variable) abort "{{{2

    let value = get(s:variables, a:variable, 'not found')
    if value ==# 'not found'
        return a:variable
    endif

    return value
endfunction "}}}2


function! s:replace_searched_variable_with_value(expr) abort "{{{2

"    Decho '== Replace Variable =='

    let expr = a:expr
"    Decho '['.expr.']= expression before variable replacement '

    let expr = s:mark_e_notation(expr)
    "strip the variable marker, if any
    let expr = substitute( expr, '\v\C^\s*'.s:valid_variable.'\s*\=\s*', '', '')
"    Decho '['.expr.']= expression striped of variable'

    "replace variable with it's value
    let expr = substitute(
                \ expr,
                \ s:variable_regex,
                \ '\=s:get_searched_variable_value(submatch(1))', 'g')
    let expr = s:mark_e_notation(expr)
    let expr = s:unmark_e_notation(expr)

"    Decho '['.expr.']= expression after variable replacement'
    return expr
endfunction "}}}2


function! s:get_searched_variable_value(variable) abort "{{{2

"    Decho '['.a:variable.']= is the variable to be replaced'
    let search_line = search('\v\C^('.b:prefix_regex.')?\V'.a:variable.'\v\s*\=\s*',
                \'bnW' )

"    Decho '['.search_line.']= search line'

    let line = s:remove_prefix_n_suffix(getline(search_line))
    let variable_value = matchstr(line,'\v\=\s*\zs-?\s*'.s:num_pat.'\ze\s*$')
"    Decho '[' . variable_value . ']= the variable value'
    if variable_value ==# ''
        call s:throw('value for '.a:variable.' not found')
    else
        return '('.variable_value.')'
    endif
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" RESULT HANDLING{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:build_result(expr, result) abort "{{{2

    let output = a:expr .' = '. a:result

    "capture variable results if they exists TODO refactor
    call s:capture_variable(output)


    let bang = s:bang
    let crunch_result_type_append = g:crunch_result_type_append
    let input_type = s:input_type

"    Decho 's:bang = <'.bang.'>'
"    Decho 'g:crunch_result_type_append = <'.crunch_result_type_append.'>'
"    Decho 's:input_type = <'.input_type.'>'

    let is_not_append_result_type = (
                \   (s:bang ==# '!' && g:crunch_result_type_append == 1) ||
                \   (s:bang ==# '' && g:crunch_result_type_append == 0) ||
                \   (
                \     (s:bang ==# '' && g:crunch_result_type_append == 2) &&
                \     (s:input_type !=# 'linewise')
                \   )
                \ )

"    Decho 'is_not_append_result_type = <'.is_not_append_result_type.'>'
    "bang isn't used and type is not append result
    if (is_not_append_result_type)
        let output = a:result
    endif
    let prefix = s:prefix
"    Decho 'prefix = <'.string(prefix).'>'
    let suffix = s:suffix
"    Decho 'suffix = <'.string(suffix).'>'
"    Decho 'output = <'.output.'>'
    return s:prefix.output.s:suffix
endfunction "}}}2


function! s:add_leading_zero(expr) abort "{{{2
    " convert .5*.34 -> 0.5*0.34

    let expr = a:expr
"    Decho '== Add Leading Zero =='
"    Decho '['.expr.']= before adding leading zero'
    let expr = substitute(expr,'\v(^|[^.0-9])\zs\.\ze([0-9])', '0&', 'g')
"    Decho '['.expr.']= after adding leading zero'
    return expr
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" PREFIX/SUFFIX {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:remove_prefix_n_suffix(expr) abort "{{{2
    " Removes the prefix and suffix from a string

    let expr = a:expr
"    Decho '== Remove Line Prefix and Suffix =='

"    Decho '['.b:prefix_regex.']= the REGEX of the prefix'
"    Decho '['.b:suffix_regex.']= the REGEX of the suffix'
"    Decho '['.expr.']= expression BEFORE removing prefix/suffix'
    let expr = substitute(expr, b:prefix_regex, '', '')
"    Decho '['.expr.']= expression AFTER removing prefix'
    let expr = substitute(expr, b:suffix_regex, '', '')
"    Decho '['.expr.']= expression AFTER removing suffix'
    return expr
endfunction "}}}2


function! s:build_prefix_and_suffix_regex() abort "{{{2
    " from a list of suffixes builds a regex expression for all suffixes in the
    " list

"    Decho '== Build Line Prefix =='
"    Decho "[".&commentstring."]=  the comment string "
    let s:comment_start = matchstr(&commentstring, '\v.+\ze\%s')
    let s:prefixs = ['*','//', s:comment_start]
    call filter (s:prefixs, "v:val !=# ''")
    let prefixs = s:prefixs
"    Decho 'prefixs = <'.string(prefixs).'>'
    let b:prefix_regex = join( map(copy(s:prefixs), 'escape(v:val, ''\/'')'), '\|')
"    Decho '['.b:prefix_regex.']= REGEX for the prefixes'
    let b:prefix_regex= '\V\^\s\*\('.b:prefix_regex.'\)\=\s\*\v'

"    Decho '== Build Line Suffix =='
"    Decho '['.&commentstring.']=  the comment string '
    let s:comment_end = matchstr(&commentstring, '\v.+\%s\zs.*')
    let s:suffixs = ['//', s:comment_end]
    call filter(s:suffixs, "v:val !=# ''")
    let suffixs = s:suffixs
"    Decho 'suffixs = <'.string(suffixs).'>'
    let b:suffix_regex = join( map(copy(s:suffixs), 'escape(v:val, ''\/'')'), '\|')
"    Decho '['.b:suffix_regex.']= REGEX for suffixes'
    let b:suffix_regex= '\V\[^ ]\{-1,}\zs\s\*\(\('.b:suffix_regex.'\)\.\*\)\=\s\*\$\v'

    "NOTE: these regex is very non magic see :h \V
endfunction "}}}2


function! s:get_user_input() abort "{{{2
    " prompt the user for an expression

    call inputsave()
    let expr = input(g:crunch_prompt)
    call inputrestore()
    return expr
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" EVALUATION {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:eval_math(expr) abort "{{{2
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


function! s:vim_eval(expr) abort "{{{2
    " Evaluates the expression and checks for errors in the process. Also
    " if there is no error echo the result and save a copy of it to the default
    " paste register

"    Decho '== Evaluate Expression =='
"    Decho '[' . a:expr . ']= the final expression'

    let result = string(eval(a:expr))
"    Decho '['.result.']= before trailing ".0" removed'
"    Decho '['.matchstr(result,'\v\.0+$').']= trailing ".0"'

    "check for trailing '.0' in result and remove it (occurs with vim eval)
    if result =~# '\v\.0+$'
        let result = string(str2nr(result))
    endif

    return result
endfunction "}}}2
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}

" ERRORS {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:echo_error(error_string) abort "{{{2

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
