" Test default value of options

call vimtest#StartTap()
call vimtap#Plan(3)

call vimtap#Is(g:crunch_tag_marker  , '#'       , "g:crunch_tag_marker")
call vimtap#Is(g:crunch_calc_prompt , 'Calc >> ', "g:crunch_calc_prompt")
call vimtap#Is(g:crunch_calc_comment, '"'       , "g:crunch_calc_comment")

call vimtest#Quit()


