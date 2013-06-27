Crunch
=====
Crunch makes using Vim as a Calculator easier and forces floating point to be
used. To use Vim as a calculator you tap into Vim's Scripting language. Without
Crunch the process goes as follows.

From insert mode or command line more:
<CTRL-R>=5+5<CR>
Then 10 is inserted into the buffer or echoed in the command line.

One Problem with this method is when you expect a floating point result from
integer division
e.g.
5/2 = 2
You can see that the result is the truncated version of the actual result.
When what you actually wanted was:
5.0/2.0 = 2.5

Or when you enter a floating point number like this
.5/2
A decimal without a leading zero produces an error when you actually wanted was
this
0.5/2 = 0.25

423.234/234 = 1.808692

Crunch takes care of these problems for you converting all integers into their
floating point equivalent, and  adds the leading zero fixing values that start
with a decimal point. It also makes doing math with Vim so much more easy.


Inspiration:
Vimcalc: Writen by Greg Sexton
https://github.com/gregsexton/VimCalc

Tagging Idea and Code:
VIM incline calculator: written by Ihar Filipau
http://vimrc-dissection.blogspot.com/2011/01/vim-inline-calculator-revisited.html

Usage
-----

1. :Crunch
    Crunch then gives you the prompt:
    Calc >>
    for you to enter you mathematical expression. The result is then available
    to be pasted from the default register.

2. :CrunchLine or <leader>ee
    Crunch Uses the selected line as the expression and adds the result to the
    end

Example: calculate area and volume given the radius. Type this:

radius# = 5
pi# = 3.1415
area# pow(#radius,2)*#pi
volume# pow(#radius,3)*#pi*4.0/3.0

First two lines work like constants denoting Pi and the radius. <leader>ee (or
^O + <leader>ee if in insert mode) when cursor on 3rd and 4th lines to evaluate
the expressions and see the results:

area# pow(#radius,2)*#pi = 78.5375
volume# pow(#radius,3)*#pi*4.0/3.0 = 523.583333


If invalid expressions are used Crunch will let you know echoing or inserting
"ERROR: Invalid Input". This same string will be yanked into the paste
register.

Demo
----
A screen capture demoing Crunch can be viewed [here]()


Make Crunch Better
------------------

If you have any tips or ideas to make Crunch better feel free to contact me or
open an issue.  
