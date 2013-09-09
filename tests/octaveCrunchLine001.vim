" Basic tests with CrunchLine command

" Load the test data. 
edit OctaveCrunchLine001.in

CrunchEval Octave
%CrunchLine

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()
