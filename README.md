Crunch
=====
Crunch makes using Vim as a Calculator easier and forces floating point to be
used. To use Vim as a calculator you tap into Vim's Scripting language. Without
Crunch the process goes as follows.

From insert mode:
<CTRL-R>=5+5<CR>
Then 10 is inserted into the buffer.

or 

From command line mode
<CTRL-R>=5+5<CR>
Then 10 echoed in the command line.

One Problem with this method is when you expect a floating point result from
integer division

e.g. 
5/2=2
You can see that the result is the truncated version of the actual result.
When what you actually wanted was: 
5.0/2.0=2.5

Or when you enter a floating point number like this 
.5/2 
A decimal without a leading zero produces an error when you actually wanted was 
this 
0.5/2=0.25

423.234/234

Crunch takes care of these problems for you converting all integers into their
floating point equivalent, and  adds the leading zero fixing values that start
with a decimal point. It also makes doing math with Vim so much more easy.

Usage
-----

1. :Crunch
    Crunch then gives you the prompt:
    Calc >> 
    for you to enter you mathematical expression

2. :'<,'>Cruch
    Use Crunch from visual mode, Crunch Uses the selected line as the expression 
    if more than one line is selected an error is echoed and Crunch is ended

In both usage cases the result is echoed in the command line. Additionally the 
Expression available to be pasted from the default paste register.  

If invalid expressions are used Crunch will let you know echoing "ERROR:
invalid input". This same string will be yanked into the paste register.

Demo
----
A screen capture demoing Crunch can be viewed [here]()


Make Crunch Better
------------------

The Following is a custom mapping for making Crunch more usfule for evaluating
math in a buffer. 

                   nnoremap <leader>eq V:Vcalc<CR>A=<ESC>p


If you have any tips or ideas to make Crunch
better feel free to contact me or open an issue.  
