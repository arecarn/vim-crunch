Overview
========

Crunch makes calculations in Vim more accessible and loosens Vim's math syntax.
Most of Crunch's syntax loosening is accomplished by extensive search and
replace. Crunch also Forces floating point to be used. 

Crunch Allows you to just type in mathematical expressions without having to
worry about the syntax as much, and getting the answer you expect. 

Demo
====
A screen capture demoing Crunch can be viewed [here]()


Usage
=====

1. :Crunch
    Crunch then gives you the following prompt in the command line:
    Calc >>
    for you to enter you mathematical expression. The result is then available
    to be pasted from the default register.

2. :CrunchLine, :'<'>CrunchLine, or <leader>cl

    Crunch Uses the current line or the visually selected lines as the
    expression(s) and adds the result to the end of the line(s).

###Variables

When using :CrunchLine  or the mapping <leader>cl you can use variables of a
sort to define values and store results. 

When declaring a variable the Tag marker comes after the variable name. So if
you wanted the variable 'cat' to equal '5' you would use '#cat 5' as your
line.

To use the variable in an expression you reverse the order of the marker and
the variable name. So if we wanted to use the variable 'cat' in an expression
we would it would look like this 'cat# + 10'

Variable names contain the ranges [a-z, A-Z, 0-9]. By default the marker for a
variable is '#' but it can be redefined by changing the g:crunch_tag_marker
global variable. 

**Example**: calculate area and volume given the radius. Type the below and
use the = 0 CrunchLine command or mapping:

    radius# = 5
    pi# = 3.1415
    area# pow(#radius,2)*#pi
    volume# pow(#radius,3)*#pi*4/3

First two lines work like constants denoting Pi and the radius.  You can then
visually select the next two lines and use either :CrunchLine, or <leader>cl
to evaluate the expressions and see the results.

    area# pow(#radius,2)*#pi = 78.5375
    volume# pow(#radius,3)*#pi*4/3 = 523.583333

If invalid expressions are used Vim will report it's errors, and may give a
result of zero.


###Comments
If you don't want a line evaluated but want to leave some text there crunch
has support for ignoring lines with comments. By default the string to start a
comment it '"' just like Vim, but this can be configured g:crunch_calc_comment
global variable. 

**Note**: The comment must be the first character in a line for the comment to
work.


Syntax Loosening
================

The following chart summarizes the features that make using math with Crunch a
better experience than vanilla Vim when just considering syntax. 

|       **Feature**         |    **With Crunch**    |   **Without Crunch**   |
| ------------------------- | --------------------- | ---------------------- |
| Multiplication Fix        |                       |                        |
|                           |`cos(0)cos(0) = 1`     |`cos(0)*cos(0) = 1.0`   |
|                           |`2sin(1) = 1.682942`   |`2*sin(1) = 1.682942`   |
|                           |`sin(1)2 = 1.682942`   |`sin(1)*2 = 1.682942`   |
|                           |`(2*3)(3*2) = 36`      |`(2*3)*(3*2) = 36`      |
|                           |`2(3*2) = 12`          |`2*(3*2) = 12`          |
|                           |`.25*4 = 1`            |`0.25*4 = 1.0`          |
|                           |                       |                        |
|Integer to Float Conversion|                       |                        |
|                           |`1/2 = 0.5`            |`1.0/2.0 = 0.5`         |
|                           |`.25*4 = 1`            |`0.25*4 = 1.0`          |
|                           |                       |                        |
|Decimals w/o Leading Zeros |                       |                        |
|                           |`.5/2 = 0.25`          |`0.5/2 = 0.25`          |
|                           |`.25*4 = 1`            |`0.25*4 = 1.0`          |
|---------------------------|-----------------------|------------------------|
|Removed Zeros In Result    |                       |                        |
|                           |`.25*4 = 1`            |`0.25*4 = 1.0`          |
|                           |`pow(2,8) = 256`       |`pow(2,8)= 256.0`       |
**Note**: all the examples 'Without Crunch' work fine with Crunch as well.

Installation
=============
Use your favorite plugin manager.
* [Neobundle](https://github.com/Shougo/neobundle.vim) <-- I use this one
* [Vundle](https://github.com/gmarik/vundle)
* [pathogen](https://github.com/tpope/vim-pathogen)
* [VAM](https://github.com/MarcWeber/vim-addon-manager)


------------------------------------------------------------------------------

------------------------------------------------------------------------------

### Make Crunch Better
If you have any tips or ideas to make Crunch better feel free to contact me or
open an issue.  

###Credits
Sources inspiration and credits for this plugin

- http://patorjk.com/
  ASCII font courtesy of Patrick Gillespie 

- https://github.com/gregsexton/VimCalc
  Greg Sexton Wrote  Vimcalc

- http://vimrc-dissection.blogspot.com/2011/01/vim-inline-calculator-revisited.html
  Ihar Filipau wrote most of the tagging code as well as VIM incline
  calculator 

- https://github.com/hrsh7th/vim-neco-calc
- hrsh7th wrote Neco-calc, and inspired the int to float conversion method
