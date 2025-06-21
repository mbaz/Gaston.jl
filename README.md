Gaston: Julia plotting using gnuplot
==================================== 

Gaston is a [Julia](https://julialang.org) package for plotting. It provides an interface to [gnuplot](http://gnuplot.info), a powerful plotting package available on all major platforms.

Current stable release is v2.0, and it has been tested with Julia LTS (1.10) and stable (1.11), on
Linux. Gaston _should_ work on any platform that runs julia and gnuplot.

Version 1.1.2 runs with Julia 1.6 and later, but it is no longer maintained. All
users are encouraged to move to version 2.

Documentation
-------------

`Gaston.jl`'s documentation can be found [here](https://mbaz.github.io/Gaston.jl/v2/).

The documentation for the older v1.x releases is [here](https://mbaz.github.io/Gaston.jl/v1/).

Why use Gaston?
--------------

Why use Gaston, when there are powerful alternatives such as Plots.jl and Makie.jl? These are some Gaston features that may be attractive to you:

* Gaston can plot:
    * Using graphical windows, and keeping multiple plots active at a time, with mouse interaction
    * Arbitrary Julia types, using recipes.
    * Directly to the REPL, using text (ASCII) or sixels
    * In Jupyter, Pluto and other IDEs
* Supports popular 2-D plots: regular function plots, stem, step, histograms, images, etc.
* Supports surface, contour and heatmap 3-D plots.
* Can save plots to multiple formats, including pdf, png and svg.
* Provides a simple interface for knowledgeable users to access gnuplot features.
* It is fast.

Installation
------------

Gaston requires gnuplot to be installed in your system. It has been tested with versions 5.4 and above, but it should work with any recent version. Gnuplot version
6 is recommended.

To install Gaston using Julia's packaging system, enter Julia's package manager prompt with `]`, and run

    pkg> add Gaston

Contributing
------------

Contributions are encouraged, in the form of issue reports, pull requests, new
tests, and new recipes.

