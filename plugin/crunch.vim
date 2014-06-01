"HEADER{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Maintainer: Ryan Carney arecarn@gmail.com
"Repository: https://github.com/arecarn/crunch
"License: WTFPL

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""}}}


" Allows the user to disable the plugin
if exists("g:loaded_crunch")
    finish
endif


let g:loaded_crunch = 1
let g:crunchMode = 'n'

augroup crunchMode
    autocmd!
    autocmd CursorMoved * let g:crunchMode = mode()
augroup END

"COMMANDS{{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=* Crunch call crunch#Crunch(<q-args>)
command! -nargs=? -range CrunchLine 
            \ <line1>,<line2>call crunch#Main(<q-args>)
command! -nargs=* -range=0 -bang CrunchDev
            \ call crunch#Dev(<count>, <line1>, <line2>, <q-args>, "<bang>")
command! -nargs=? CrunchBlock call crunch#EvalPar(<q-args>)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"CrunchLine mapping
"Allows for users to define their own mappings. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchEvalLine')
    map <unique> <leader>cl <Plug>CrunchEvalLine
endif

noremap <unique> <script> <Plug>CrunchEvalLine <SID>CrunchLine
noremap <SID>CrunchLine :CrunchLine<CR>

noremap <unique> <script> <Plug>CrunchEvalLineExc <SID>CrunchLineExc
noremap <SID>CrunchLineExc :CrunchLine -exclusive<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"CrunchBlock mapping
"Allows for users to define their own mappings. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !hasmapto('<Plug>CrunchEvalBlock')
    map <unique> <leader>cb <Plug>CrunchEvalBlock
endif

noremap <unique> <script> <Plug>CrunchEvalBlock <SID>CrunchBlock
noremap <SID>CrunchBlock :CrunchBlock<CR>

noremap <unique> <script> <Plug>CrunchEvalBlockExc <SID>CrunchBlockExc
noremap <SID>CrunchBlockExc :CrunchBlock -exclusive<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <silent> g= :set opfunc=<SID>Crunchy<CR>g@
vmap <silent> g= :<C-U>call <SID>Crunchy(visualmode())<CR>
nmap <silent> g== :normal! V<CR>:<C-U>call <SID>Crunchy(visualmode())<CR>


function! s:Crunchy(type)
  " backup settings that we will change
  let sel_save = &selection
  let cb_save = &clipboard
  " make selection and clipboard work the way we need
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  " backup the unnamed register, which we will be yanking into
  let reg_save = @@
  " yank the relevant text, and also set the visual selection (which will be reused if the text
  " needs to be replaced)
  if a:type =~ '^\d\+$'
    " if type is a number, then select that many lines
    silent exe 'normal! V'.a:type.'$y'
  elseif a:type =~ '^.$'
    " if type is 'v', 'V', or '<C-V>' (i.e. 0x16) then reselect the visual region
    silent exe "normal! `<" . a:type . "`>y"
  elseif a:type == 'line'
    " line-based text motion
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    " block-based text motion
    silent exe "normal! `[\<C-V>`]y"
  else
    " char-based text motion
    silent exe "normal! `[v`]y"
  endif
  " call the user-defined function, passing it the contents of the unnamed register
  let repl = crunch#Visual(@@)
  " if the function returned a value, then replace the text
  if type(repl) == 1
    " put the replacement text into the unnamed register, and also set it to be a
    " characterwise, linewise, or blockwise selection, based upon the selection type of the
    " yank we did above
    call setreg('@', repl, getregtype('@'))
    " relect the visual region and paste
    normal! gvp
  endif
  " restore saved settings and register value
  let @@ = reg_save
  let &selection = sel_save
  let &clipboard = cb_save
endfunction
" vim:foldmethod=marker
