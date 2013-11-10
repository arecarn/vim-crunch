" Test default mapping and that it only occurs if user doesn't has custom
" mappings

call vimtest#StartTap()
call vimtap#Plan(7)

call vimtap#Is(maparg('\cl'), '<Plug>CrunchEvalLine', "maparg \cl")
call vimtap#Is(maparg('\cb'), '<Plug>CrunchEvalBlock', "maparg \cb")
call vimtap#Is(exists('g:loaded_crunch'), 1, "exists g:loaded_crunch")


unmap \cl
unmap \cb
map <unique> <leader>cx <Plug>CrunchEvalLine
map <unique> <leader>cy <Plug>CrunchEvalBlock
unlet g:loaded_crunch
source _setup.vim

call vimtap#Is(maparg('\cl'), '', "detect CrunchEvalLine already mapped")
call vimtap#Is(maparg('\cb'), '', "detect CrunchBlock already mapped")

unmap \cx
unmap \cy
map <unique> <leader>cx <Plug>CrunchEvalLineExc
map <unique> <leader>cy <Plug>CrunchEvalBlockExc
unlet g:loaded_crunch
source _setup.vim

call vimtap#Is(maparg('\cl'), '', "detect CrunchEvalLineExc already mapped")
call vimtap#Is(maparg('\cb'), '', "detect CrunchEvalBlockExc already mapped")



call vimtest#Quit()


