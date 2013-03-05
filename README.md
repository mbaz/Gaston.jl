Gaston: Julia plotting using gnuplot
==================================== 

Gaston provides an interface to plot using gnuplot.

Installation
------------

Gaston requires gnuplot to be installed in your system. It has been tested
with version 4.6

To install Gaston, run

    julia> Pkg.add("Gaston")

Then, load the module:

    julia> using Gaston

Documentation
-------------

To build the PDF documentation, cd into the doc/ subdirectory and type
'make help'. You can download the pre-build documentation from
https://bitbucket.org/mbaz/gaston/downloads

Demo
----

Gaston includes a demo that showcases its current capabilities:

    julia> gaston_demo()

This function is defined in Gaston/src/gaston\_demo.jl.

Tests
-----

Gaston includes many tests, wich you can run to make sure your installation is
working properly. To run the tests, do

    julia> gaston_tests()

All tests should pass.
