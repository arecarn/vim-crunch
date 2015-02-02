#Crunch ![travis-ci](https://travis-ci.org/arecarn/crunch.vim.svg?branch=master)

[![Join the chat at https://gitter.im/arecarn/crunch.vim](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/arecarn/crunch.vim?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

###A calculator inside Vim

##Overview

Crunch makes calculations in Vim more accessible and loosens Vim's math
syntax.  Most of Crunch's looser syntax is accomplished by extensive search
and replace.  Crunch also forces floating point to be used.

Requirements: Vim compiled with `+float` feature.

Crunch allows you to just type in mathematical expressions without having to
worry about the syntax as much.


##Usage

* `g={motion}` Evaluate the text that {motion} moves over

* `g==` Evalue the current line appending the result

* `:[range]Crunch[!]`
   Evaluates the current visual selection or provided range and adds result to
   the end of the line(s) With the [!] crunch does not append the result but
   replaces the provided range or visual selection with the result this
   behavior can be reversed  by setting  `g:crunch_result_type_append` = 0

* `:Crunch`
    Provides a prompt in the command for you to enter your mathematical
    expression. The result is then available to be pasted from the default
    register.

* `:Crunch [expr]`
    Where [expr] is some mathematical expression to be evaluated. The result
    is then available to be pasted from the default register.

##Demos

Comming Sooner or Later

------------------------------------------------------------------------------


##Looser Syntax

The following chart shows the looser math syntax provided with Crunch,
compared to the default math syntax.

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

If you don't have an preferred method, check out some of the following popular
methods
* [Neobundle](https://github.com/Shougo/neobundle.vim)
* [Vundle](https://github.com/gmarik/vundle)
* [pathogen](https://github.com/tpope/vim-pathogen)
* [VAM](https://github.com/MarcWeber/vim-addon-manager)

------------------------------------------------------------------------------

###Credits

Sources inspiration and credits for this plugin

- http://patorjk.com/
  ASCII font courtesy of Patrick Gillespie

- https://github.com/gregsexton/VimCalc
  Greg Sexton Wrote Vimcalc

- http://vimrc-dissection.blogspot.com/2011/01/vim-inline-calculator-revisited.html
  Ihar Filipau inspired most of the variable code

- https://github.com/hrsh7th/vim-neco-calc
  hrsh7th wrote Neco-calc, and provided a solid int to float conversion method

- https://github.com/sk1418/HowMuch
  sk1418 wrote a similar plugin with visual block/characterwise evaluation, as
  well as providing an even better int to float conversion method

- Marcelo Montu (github: mMontu)
  For contributing to make crunch more user friendly and useful
