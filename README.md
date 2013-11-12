#Crunch

###An easier way to perform calculations inside Vim

##Overview

Crunch makes calculations in Vim more accessible and loosens Vim's math syntax.
Most of Crunch's looser syntax is accomplished by extensive search and replace.
Crunch also forces floating point to be used. 

Requirements: Vim compiled with `+float` feature.

Crunch allows you to just type in mathematical expressions without having to
worry about the syntax as much.


##Usage
*   `:Crunch <args>`

    Where <args> is some mathematical expression to be evaluated. The result
    is then available to be pasted from the default register.

*  `:Crunch`

    Crunch then gives you the following prompt in the command line:
    Calc >>
    for you to enter you mathematical expression. The result is then available
    to be pasted from the default register.

*  `:CrunchLine`, `:'<'>CrunchLine`, or `<leader>cl`

    Crunch Uses the current line or the visually selected lines as the
    expression(s) and adds the result to the end of the line(s). When the
    expression(s) changes using :CrunchLine again will reevaluate the line(s)

*  `:CrunchBlock`, or `<leader>cb`

    Crunch Uses the current paragraph (block of text starting and ending with
    an empty line) as the expressions and adds the result to the end of the
    lines. When a expressions in a paragraph changes using :CrunchBlock again
    will reevaluate them

##Demos

![Command Line Mode](http://i.imgur.com/Fu0j3OE.gif) 

Crunch works from the command line for quick off hand calculations. The result
of these calculations are then available to be pasted.

---


![Variables](http://i.imgur.com/fZw0B4S.gif)

Variables can be used to save expressions so they can be used later.

---

![Visual Selection](http://i.imgur.com/U4pkM6d.gif) 

Multiple lines can be evaluated/reevaluated , with visual selections.
Optionally single lines can be evaluated/reevaluated.

---

![Ignores Comments](http://i.imgur.com/yu2xGWk.gif)

Crunch ignores Comments, by removing them evaluating lines then putting them
back in. The ignored comments are variable based file type using the
`conmmentstring` variable. Crunch also always ignores a leading or following
`//` and `*` 

---

![CrunchBlock](http://i.imgur.com/i3IDNIR.gif) 

Paragraphs can be evaluated using the `:CrunchBlock` command or the default
mapping `<leader>cb`

##Looser Syntax

The following chart shows the looser math syntax provided with Crunch, compared 
to the default math syntax.

|       **Feature**         |    **With Crunch**      |  **Without Crunch** |
| ------------------------- | ---------------------   | ------------------- |
|Implied Multiplication     |                         |                     |
|                           |`cos(0)cos(0) = 1`       |`cos(0)*cos(0) = 1.0`|
|                           |`2sin(1) = 11.682942`    |`2*sin(1) = 1.682942`|
|                           |`sin(1)2 = 1.682942`     |`sin(1)*2 = 1.682942`|
|                           |`(2*3)(3*2) = 36`        |`(2*3)*(3*2) = 36`   |
|                           |`2(3*2) = 12`            |`2*(3*2) = 12`       |
|Integer to Float Conversion|                         |                     |
|                           |`1/2 = 0.5`              |`1.0/2.0 = 0.5`      |
|                           |`.25*4 = 1`              |`0.25*4 = 1.0`       |
|Decimals w/o Leading Zeros |                         |                     |
|                           |`.5/2 = 0.25`            |`0.5/2 = 0.25`       |
|                           |`.25*4 = 1`              |`0.25*4 = 1.0`       |
|Removed Zeros In Result    |                         |                     |
|                           |`0.25*4 = 1`             |`0.25*4 = 1.0`       |
|                           |`pow(2,8) = 256`         |`pow(2,8)= 256.0`    |
                                                                             
##Installation
If you don't have an preferred method, I recommend one of the following plugin
managers.
* [Neobundle](https://github.com/Shougo/neobundle.vim)
* [Vundle](https://github.com/gmarik/vundle)
* [pathogen](https://github.com/tpope/vim-pathogen)
* [VAM](https://github.com/MarcWeber/vim-addon-manager)

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
