Gaston: Julia plotting using gnuplot
==================================== 

Gaston is a [Julia](https://julialang.org)  package for plotting. It provides an interface to [gnuplot](http://gnuplot.info), a powerful plotting package available on all major platforms.

Current stable release is v0.10.0, and it is tested with Julia 1.1.0.

|                  | Stable (v0.10)  | Dev               |
|:----------------:|:----------------: | :----------------:|
| **Build Status** | [![Build Status](https://travis-ci.org/mbaz/Gaston.jl.svg?branch=v0.10.0)](https://travis-ci.org/mbaz/Gaston.jl) | [![Build Status](https://travis-ci.org/mbaz/Gaston.jl.svg?branch=master)](https://travis-ci.org/mbaz/Gaston.jl) |

Documentation
-------------

Gaston's documentation can be found [here](https://mbaz.github.io/Gaston.jl/v0.10.0/).

Why use Gaston?
--------------

Why use Gaston, when there are modern, powerful alternatives such as Plots.jl and MakiE.jl? These are some Gaston features that may be attractive to you:

* Gaston can plot:
    * Using graphical windows, and keeping multiple plots active at a time, with mouse interaction
    * Directly to the REPL, using text (ASCII) or sixels
    * In Jupyter and Juno
* Supports popular 2-D plots: regular function plots, stem, step, histograms, images, etc.
* Supports surface, contour and heatmap 3-D plots.
* Can save plots to multiple formats, including pdf, png and svg.
* Provides a simple interface for knowledgeable users to access gnuplot features not exposed by Gaston.
* Fast: time to load package, plot, and save to pdf is around five seconds.

Gaston's philosophy is that plotting to the screen should be fast and non-ugly. Publication-quality plots are the domain of TiKZ and pgfplots.

Knowledge of gnuplot is not required. Users familiar with gnuplot, however, will be able to take advantage of Gaston's facilities to access the (vast) feature set not directly exposed by Gaston.

Installation
------------

Gaston requires gnuplot (i.e. gnuplot-qt) to be installed in your system. It has been tested with versions 5.0 and above, and version 5.2 is recommended. Gaston also requires Julia v1.1.

To install Gaston using Julia's packaging system, enter Julia's package manager prompt with `]`, and run

    (v1.1) pkg> add Gaston

Tests
-----

Gaston includes many tests, wich you can run to make sure your installation is
working properly. To run the tests, enter Julia's package manager with `]` and run

    (v1.1) pkg> test Gaston

All tests should pass.
