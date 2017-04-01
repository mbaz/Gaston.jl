Gaston: Julia plotting using gnuplot
==================================== 

Gaston provides an interface to plot using gnuplot.

Why use Gaston?
--------------

The julia plotting ecosystem has improved a lot in the last couple of years. With plenty of powerful packages to choose from, why use Gaston? These are some Gaston features that may be attractive to you:

1. Easy and fast plotting to the screen or inside an IJulia notebook.
1. Multiple plots on the screen at the same time.
1. Syntax familiar to Matlab and Octave users.
1. No dependencies except GnuPlot itself.
1. Focus on simplicity and speed. I use Gaston when I need to plot something quickly. If I need publication-quality plots, I use PGFPlots.
1. Support for 3D plots, with mouse zoom, rotation, etc.
1. Support for many of the types of plots that GnuPlot supports: histograms, images, financial bars, etc.
1. Easy saving of plots to a file, supporting many file formats.

Having said that, Gaston also shares GnuPlot's limitations. The main one is that GnuPlot is not a library; it is designed to be used interactively. Gaston simulates a user typing interactive commands in a GnuPlot session; we try to be as robust as possible, but this set up is always fragile.

Installation
------------

Gaston requires GnuPlot to be installed in your system. It has been tested
with versions 4.6 and above. Gaston also requires Julia v0.5.

To install using Julia's packaging system, run `Pkg.add("Gaston")`.

Documentation
-------------

To build the PDF documentation, cd into the doc/ subdirectory and type
'make help'. You can download the pre-build documentation from
https://bitbucket.org/mbaz/gaston/downloads

A note on OSX
-------------

Recent versions of OSX removed support for the aqua terminal from gnuplot.
Before attempting to use aqua in Gaston, open a terminal and run this
command:

    gnuplot -e "set term" | grep aqua

If nothing is printed, then you do not have support for the aqua terminal and
should not attempt to use it in Gaston. By default, Gaston uses the wxt
terminal. You can verify if your version of gnuplot supports it by issuing

    gnuplot -e "set term" | grep wxt

Again, if no output is printed, your gnuplot does not support wxt. In this
case, you need to run this command before any other Gaston command:

    set_terminal("x11")

x11 is a fallback terminal with less bells and whistles than wxt or aqua.

If you want to save your plots to a file, please see [this discussion first](https://github.com/mbaz/Gaston.jl/issues/4).

Demo
----

Gaston includes a demo that showcases its current capabilities:

    julia> gaston_demo()

This function is defined in Gaston/src/gaston\_demo.jl.

Tests
-----

Gaston includes many tests, wich you can run to make sure your installation is
working properly. To run the tests, do

    julia> Pkg.test("Gaston")

All tests should pass.
