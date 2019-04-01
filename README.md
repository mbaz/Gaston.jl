Gaston: Julia plotting using gnuplot
==================================== 

Gaston is a [Julia](https://julialang.org)  package for plotting. It provides an interface to [gnuplot](http://gnuplot.info), a powerful plotting package available on all major platforms.

Current stable release is 0.9.0, and it is tested with Julia 1.1.0.

Gaston release 0.7.4 is the last release compatible with Julia 0.6 or below. This Gaston release is no longer under maintenance, though.

| **Build Status** |
|:----------------:|
| [![][travis-img]][travis-url] |

Why use Gaston?
--------------

Why use Gaston, when there are plenty of modern, powerful alternatives such as Plots.jl and Gadfly.jl?  These are some Gaston features that may be attractive to you:

1. Emphasis on fast, simple plotting to the screen or in a Jupyter notebook.
1. Since the code is so simple (less than 1,500 lines, with no dependencies beyond Julia Base), it loads quickly, even without precompilation.
1. Support for 2D, 3D, histogram and image plots, with mouse zoom, rotation, etc.
1. Support for error bars and finance bars.
1. Syntax not too different from that of Matlab and Octave.
1. Capable of handling multiple plots on the screen at the same time.
1. Easy saving of plots to a file, supporting the more common file formats.

My philosophy is that plotting to the screen should be fast and non-ugly. Publication-quality plots are the domain of TiKZ and pgfplots.

Having said that, Gaston also shares GnuPlot's limitations. The main one is that gnuplot is not a library; it is designed to be used interactively. Gaston simulates a user typing interactive commands in a gnuplot session. While Gaston provides many safeguards, there is always the possibility that something goes wrong and a restart is required.

Installation
------------

Gaston requires gnuplot to be installed in your system. It has been tested with versions 5.0 and above, and version 5.2 is recommended. Gaston also requires Julia v1.1.

To install Gaston using Julia's packaging system, enter Julia's package manager prompt with `]`, and run

    (v1.1) pkg> add Gaston

Documentation
-------------

There is a tutorial available [here](https://nbviewer.jupyter.org/github/mbaz/Gaston.jl/blob/master/doc/gaston-tutorial.ipynb).

Additional reference documentation is in the works.

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

A further alternative is the qt terminal. If it is not supported, then you either need to install a gnuplot version with support for modern terminals, or revert to the x11 terminal with:

    set_terminal("x11")

x11 is a fallback terminal with less bells and whistles than qt, wxt or aqua.

Tests
-----

Gaston includes many tests, wich you can run to make sure your installation is
working properly. To run the tests, enter Julia's package manager with `]` and run

    (v1.1) pkg> test Gaston

All tests should pass.

[travis-url]: https://api.travis-ci.org/mbaz/Gaston.jl
[travis-img]: https://api.travis-ci.org/mbaz/Gaston.jl.svg?tag=v0.9.0
