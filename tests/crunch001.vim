" Basic tests with Crunch command

call crunch#Crunch('cos(0)cos(0)')
call crunch#Crunch('2sin(1)')
call crunch#Crunch('sin(1)2')
call crunch#Crunch('(2*3)(3*2)')
call crunch#Crunch('2(3*2)')
call crunch#Crunch('.25*4')
call crunch#Crunch('1/2')
call crunch#Crunch('.5/2')
call crunch#Crunch('pow(2,8)')

call vimtest#Quit()


