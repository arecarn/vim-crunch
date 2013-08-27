" Basic test with CrunchLine command using comment string

" Load the test data. 
edit crunchLine003.in

call search('pow')
.CrunchLine

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()


