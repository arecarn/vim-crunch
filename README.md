crunch
======

crunch makes calculations in Vim more accessible by providing an operator to
evaluate mathematical expressions, loosening Vim's math syntax, and forcing
integers into floating point numbers.

Usage
-----

| Mode   | Key Mapping | Description                                |
|--------|-------------|--------------------------------------------|
| normal | g={motion}  | Evaluate the text that {motion} moves over |
| normal | g==         | Evaluate the current line                  |
| visual | g=          | Evaluate the highlighted expressions       |

* `:[range]Crunch[!]`
    * Evaluates the current visual selection or provided range and adds result
      to the end of the line(s) With the [!] crunch does not append the result
      but replaces the provided range or visual selection with the result this
      behavior can be reversed  by setting  `g:crunch_result_type_append` = 0

* `:Crunch`
    * Provides a prompt in the command for you to enter your mathematical
      expression. The result is then available to be pasted from the default
      register.

* `:Crunch {expression}`
    * Where {expression} is some mathematical expression to be evaluated. The
      result is then available to be pasted from the default register.

Requirements
------------
* [selection.vim](https://github.com/arecarn/selection.vim)
* Vim compiled with `+float` feature

------------------------------------------------------------------------------

Math With Looser Syntax
-----------------------
The following chart shows the looser math syntax provided with crunch, compared
to the default math syntax.

| Feature                     | With crunch         | Without crunch      |
|-----------------------------|---------------------|---------------------|
| Implied Multiplication      |                     |                     |
|                             | cos(0)cos(0) = 1    | cos(0)*cos(0) = 1.0 |
|                             | 2sin(1) = 1.682942  | 2*sin(1) = 1.682942 |
|                             | sin(1)2 = 1.682942  | sin(1)*2 = 1.682942 |
|                             | (2*3)(3*2) = 36     | (2*3)*(3*2) = 36    |
|                             | 2(3*2) = 12         | 2*(3*2) = 12        |
| Integer to Float Conversion |                     |                     |
|                             | 1/2 = 0.5           | 1.0/2.0 = 0.5       |
|                             | .25*4 = 1           | 0.25*4 = 1.0        |
| Decimals w/o Leading Zeros  |                     |                     |
|                             | .5/2 = 0.25         | 0.5/2 = 0.25        |
|                             | .25*4 = 1           | 0.25*4 = 1.0        |
| Removed Zeros In Result     |                     |                     |
|                             | 0.25*4 = 1          | 0.25*4 = 1.0        |
|                             | pow(2,8) = 256      | pow(2,8)= 256.0     |
