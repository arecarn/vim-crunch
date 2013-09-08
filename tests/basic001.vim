" Test default value of options

call vimtest#StartTap()
call vimtap#Plan(2)

call vimtap#Is(g:crunch_calc_prompt , 'Calc >> ', "g:crunch_calc_prompt")
call vimtap#Is(g:crunch_calc_comment, '"'       , "g:crunch_calc_comment")

call vimtest#Quit()


