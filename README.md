#Crunch

###Perform incline calculations inside a Vim buffer

##Overview
Crunch makes calculations in Vim more accessible and loosens Vim's math syntax.
Most of Crunch's syntax loosening is accomplished by extensive search and
replace. Crunch also forces floating point to be used. 

Crunch allows you to just type in mathematical expressions without having to
worry about the syntax as much, and getting the answer you expect. 

##Demo

![Command Line Mode](http://i.imgur.com/uJbfln9.gif) 

Crunch works from the command line for quick off hand calculations. The result
of these calculations are then available to be pasted.


![Variables](http://i.imgur.com/LHzT4HY.gif)

Variables can be used to save expressions so they can be used later.

![Visual Selection](http://i.imgur.com/3KTujLF.gif) 

Multiple lines can be evaluated/reevaluated , with visual selections.
Optionally single lines can be evaluated/reevaluated.

##Usage
1. :Crunch
    Crunch then gives you the following prompt in the command line:
    Calc >>
    for you to enter you mathematical expression. The result is then available
    to be pasted from the default register.

2. :CrunchLine, :'<'>CrunchLine, or <leader>cl
    Crunch Uses the current line or the visually selected lines as the
    expression(s) and adds the result to the end of the line(s).

###Variables

When using :CrunchLine or the mapping <leader>cl you can use variables of a
sort to define values and store results. 

* Declaring a variable like this: 
  `#cat 5` 

* Use a variable in an expression like this:
  `cat# +10`

* Variable names contain the ranges [a-z, A-Z, 0-9]. By default the marker for
  a variable is '#' but it can be redefined by changing the g:crunch_tag_marker
  global variable. 

###Example 

Calculate area and circumference of a sphere given the radius. Type the below
and use the CrunchLine command or mapping <leader>cl:

    radius# = 5
    pi# = 3.1415
    area# pow(#radius,2)*#pi
    circumference# 2 * #pi * #radius 

First two lines work like constants denoting Pi and the radius. You can then
visually select the next two lines and use either :CrunchLine, or <leader>cl
to evaluate the expressions and see the results.

    area# pow(#radius,2)*#pi = 78.5375
    circumference# 2 * #pi * #radius = 31.415

If invalid expressions are used Vim will report it's errors, and may give a
result of zero.


###Comments
If you don't want a line evaluated but want to leave some text there crunch
has support for ignoring lines with comments. By default the string to start a
comment it '"' just like Vim, but this can be configured g:crunch_calc_comment
global variable. 

**Note**: The comment must be the first character in a line for the comment to
work.


##Syntax Loosening

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
|                           |                       |                        |
|Removed Zeros In Result    |                       |                        |
|                           |`.25*4 = 1`            |`0.25*4 = 1.0`          |
|                           |`pow(2,8) = 256`       |`pow(2,8)= 256.0`       |
**Note**: all the examples 'Without Crunch' work fine with Crunch as well.

##Installation
Use your favorite plugin manager.
* [Neobundle](https://github.com/Shougo/neobundle.vim) <-- I use this one
* [Vundle](https://github.com/gmarik/vundle)
* [pathogen](https://github.com/tpope/vim-pathogen)
* [VAM](https://github.com/MarcWeber/vim-addon-manager)


------------------------------------------------------------------------------
------------------------------------------------------------------------------

### Make Crunch Better
I'm pretty new to Vim Script so any tips are appreciated. Think you can make
Crunch better? Fork it on GitHub and send a pull request. If you find bugs,
want new functionality contact me by making an issue on
[GitHub](https://github.com/arecarn/crunch/issues) and I'll see what I can do. 

###Credits
Sources inspiration and credits for this plugin

- http://patorjk.com/
  ASCII font courtesy of Patrick Gillespie 

- https://github.com/gregsexton/VimCalc
  Greg Sexton Wrote Vimcalc

- http://vimrc-dissection.blogspot.com/2011/01/vim-inline-calculator-revisited.html
  Ihar Filipau wrote most of the tagging code as well as VIM incline
  calculator 

- https://github.com/hrsh7th/vim-neco-calc
  hrsh7th wrote Neco-calc, and inspired the int to float conversion method
