"Crunch Line maping
if g:crunch_load_default_mappings || !exists('g:crunch_load_default_mappings')
    map <Plug>Crunch_Line :CrunchLine<CR>
    nmap <leader>ee <silent><Plug>Crunch_Line
endif
