"=============================================================================
"Crunch Line mapping
"Allows for users to define their own mappings. 
"=============================================================================
if g:crunch_load_default_mappings || !exists('g:crunch_load_default_mappings')
    noremap <leader>cl :CrunchLine<CR>
endif
