" Load the test data. 
edit  crunchDev_VLn_BlankLines.in
execute "normal! ggVG\"ay"
call crunch#VisualBlock(@a)

" Save the processed buffer contents 
call vimtest#SaveOut()
call vimtest#Quit()