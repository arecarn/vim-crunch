" Basic test with CrunchLine command

" Load the test data. 
edit crunchLine001.in

call search('pow')
.CrunchLine

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()


