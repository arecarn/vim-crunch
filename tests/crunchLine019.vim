" Basic test with CrunchLine command and variables

" Load the test data. 
edit crunchLine019.in

normal! 5G
CrunchBlock

normal! 8G
CrunchBlock

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()
