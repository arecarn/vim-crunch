" Load the test data. 
edit crunchDevSelections.in
execute "normal! gg|fs\<C-V>9j11l\"ay"
call crunch#VisualBlock(@a)

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()
