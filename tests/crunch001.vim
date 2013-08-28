" Basic tests with Crunch command

echomsg 'crunch#Crunch tests:'
call crunch#Crunch('cos(0)cos(0)')
call crunch#Crunch('2sin(1)')
call crunch#Crunch('sin(1)2')
call crunch#Crunch('(2*3)(3*2)')
call crunch#Crunch('2(3*2)')
call crunch#Crunch('.25*4')
call crunch#Crunch('1/2')
call crunch#Crunch('.5/2')
call crunch#Crunch('pow(2,8)')

echomsg ''
echomsg 'Crunch tests:'
Crunch cos(0)cos(0)
Crunch 2sin(1)
Crunch sin(1)2
Crunch (2*3)(3*2)
Crunch 2(3*2)
Crunch .25*4
Crunch 1/2
Crunch .5/2
Crunch pow(2,8)

call vimtest#Quit()


