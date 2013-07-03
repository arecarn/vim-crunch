nnoremap <silent> <Plug>Crunch_Line :CrunchLine<CR>

"Crunch Line maping
if g:crunch_load_default_mappings || !exists('g:crunch_load_default_mappings')
    nmap <leader>ee <silent><Plug>Crunch_Line
endif
