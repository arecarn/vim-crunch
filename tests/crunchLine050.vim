" Basic tests with CrunchLine command

" Load the test data. 
edit crunchLine050.in

%CrunchLine

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()
