# 1520 System ROM

Preservation of this contents is a result of joined effort of the community. Fully analysed disassembly provided by Soci/Singularcrew in an amazing "no time" after the initial ROM dump has been made available by Jim Brain. Major contributors:

* Jim Brain
* Soci/Singularcrew
* Greg King
* Gerrit Heitsch
* [...]

## Assembling the sources

Source files have been made compatible with major (cross-)assemblers. They have been tested and proven to generate an exact binary copy of the original when using:

### [xa](http://www.floodgap.com/retrotech/xa/)
    $ xa -o 325340-01.bin 325340-01.s

### [64tass](http://tass64.sourceforge.net)
    $ 64tass -b -o 325340-01.bin 325340-01.s

### [ca65](http://cc65.github.io/cc65/doc/ca65.html) from [cc65](http://cc65.github.io/cc65/) cross-development package
    $ cl65 -o 325340-01.bin -t none --feature pc_assignment 325340-01.s

For all the above no modifications to the source files are required.