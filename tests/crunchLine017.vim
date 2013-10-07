" Basic test with CrunchLine command and variables

" Load the test data. 
edit crunchLine017.in

5,7CrunchLine -exclusive
"ranges like this don't work becasue '< isn't set
9,10CrunchLine -exc
normal!13G
CrunchLine -exclusive
normal!15G
CrunchBlock -exc

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()
