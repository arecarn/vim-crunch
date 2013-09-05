" Basic test with CrunchLine command and variables

" Load the test data. 
edit crunchLine007.in

%CrunchLine

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()
