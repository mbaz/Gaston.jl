# Gaston.jl

!!! note "Gaston v1.x is in maintenance mode"
    This documentation is for Gaston version 1.x. This version is no longer under development. It is
    recommended to switch to [version 2](https://mbaz.github.io/Gaston.jl/v2/).

Gaston (source code [here](https://github.com/mbaz/Gaston.jl)) is a Julia package for plotting. It provides an interface to [gnuplot](http://www.gnuplot.info), a mature, powerful, and actively developed plotting package available on all major platforms.

Gaston emphasizes easy and fast plotting on the screen, notebook or IDE. Knowledge of gnuplot is not required, but some familiarity is beneficial. Gaston also exposes the full power of gnuplot, for more expert users.

```@example t2
using Gaston, SpecialFunctions
set(reset=true) # hide
set(termopts="size 550,325 font 'Consolas,11'") # hide
x = y = 0:0.075:10
surf(x, y, (x,y) -> besselj0(y)*x^2, with = "pm3d",
     Axes(view = (45, 45),
          pm3d = "lighting primary 0.5 specular 0.4",
          key = :off)
     )
```

(Image inspired by [What's new in gnuplot 5.2?](https://lwn.net/Articles/723818/))

## Gaston features

* Plot using graphical windows, and keeping multiple plots active at a time, with mouse interaction. A browser is not required to show plots.
* Plot also directly to the REPL, using text (ASCII) or [sixels](https://en.wikipedia.org/wiki/Sixel).
* Plot in Jupyter, Juno or VS Code.
* "Recipes" to generate common 2-D and 3-D plots, such as stem plots, histograms, images, surfaces, contour and heatmaps.
* Easy definition of custom plotting commands for specific types, or with specific defaults.
* Save plots to multiple formats, including pdf, png and svg.
* Color palettes from [ColorSchemes.jl](https://github.com/JuliaGraphics/ColorSchemes.jl).
* Export plots for integration into Latex documents.
* A simple interface to almost the full power of gnuplot, for users who have more experience with it.
* Fast first plot: load package, plot, and save to pdf in less than six seconds. Subsequent plots take a few hundreds of milliseconds.
* A simple interface to manage multiple plots, using commands such as `figure()`, `closeall()`, etc.

### Gaston and Gnuplot.jl: two philosophies

[Gnuplot.jl](https://github.com/gcalderone/Gnuplot.jl) is another front-end for gnuplot, with comparable capabilities to Gaston. An example serves to illustrate the differences in how the two packages approach the interface problem. Consider [this example plot](https://gcalderone.github.io/Gnuplot.jl/v1.3.0/basic/#Multiple-datasets,-logarithmic-axis,-labels-and-colors,-etc.-1):

```julia
x = 1:0.1:10
@gp    "set grid" "set key left" "set logscale y"
@gp :- "set title 'Plot title'" "set label 'X label'" "set xrange [0:*]"
@gp :- x x.^0.5 "w l tit 'Pow 0.5' dt 2 lw 2 lc rgb 'red'"
@gp :- x x      "w l tit 'Pow 1'   dt 1 lw 3 lc rgb 'blue'"
@gp :- x x.^2   "w l tit 'Pow 2'   dt 3 lw 2 lc rgb 'purple'"
```

This shows that Gnuplot.jl essentially allows one to write gnuplot commands directly in Julia. The same plot in Gaston would be:

```@example t2
x = 1:0.1:10
plot(x, x.^0.5,
     w = "l",
     legend = "'Pow 0.5'",
     dt = 2,
     lw = 2,
     lc = :red,
     Axes(grid = :on,
          key = "left",
          axis = "semilogy"))
plot!(x, x,
      w = :l,
      leg = :Pow_1,
      dt = 1,
      lw = 3,
      lc = :blue)
plot!(x, x.^2,
      curveconf = "w l tit 'Pow 2' dt 3 lw 2 lc 'purple'")
```

In summary, Gaston offers a function-based interface, and gnuplot commands can be specified in a few different ways, with convenient notation, such as the optional use of "legend" instead of gnuplot's "title", symbols to avoid typing quote marks (") all the time, and others that are described later in this document.

## Installation

Gaston requires Julia version 1.3.0 or above, and requires Gnuplot version 5.0 or above (version 5.2.8 is recommended). You should install gnuplot on your system prior to using Gaston. On Linux, it is highly recommended that you select a version with support for Qt: on Debian and Ubuntu, you will need `gnuplot-qt`.

To install Gaston from the Julia REPL, run

```julia
julia> ]add Gaston
```

Typing `]` switches the Julia REPL to the package manager, and the `add` command installs the package. To exit the package manager, hit the backspace key.

## Gnuplot configuration

Gaston respects user configuration settings in gnuplot's startup file. Left un-configured, gnuplot's plots are less than attractive. The following minimum configuration is suggested (and was used to generate the plots in this document):

    set linetype 1 lc rgb "blue" pt 3
    set linetype 2 lc rgb "red" pt 4
    set linetype 3 lc rgb "green" pt 6
    set linetype 4 lc rgb "black" pt 12
    set linetype 5 lc rgb "blue" pt 5
    set linetype 6 lc rgb "red" pt 1
    set linetype 7 lc rgb "green" pt 2
    set linetype 8 lc rgb "black" pt 7
    set linetype cycle 8
    set style data lines
    set key noautotitle
    set auto fix
    set offsets graph .05, graph .05, graph .05, graph .05

The configuration file is `~/.gnuplot` in Unix-like systems, and `%APPDATA%\GNUPLOT.INI` in Windows.

## Next steps

Load Gaston into your Julia session with

```julia
using Gaston
```

The [Introduction to plotting](@ref) has more information about basic use and configuration.

There is a [2-D plotting tutorial](@ref twodeetut) and a [3-D plotting tutorial](@ref threedeetut).

The [Extending Gaston](@ref) section explains how to extend Gaston by creating your own "recipes", both for specific kinds of plots, and for plotting data of specific types.

There is a section on  [Managing multiple figures](@ref) and all related commands.

The [2-D Gallery](@ref twodeegal) and [3-D Gallery](@ref threedeegal) show many plotting examples.

The [Usage notes and FAQ](@ref) section includes additional usage examples and answers frequent questions.

## Gnuplot resources

These websites have more information on gnuplot and how to use it:

* [Official website](http://www.gnuplot.info/)
* [Official demo gallery](http://gnuplot.sourceforge.net/demo_5.2/)
* [PDF documentation for 5.2](http://www.gnuplot.info/docs_5.2/Gnuplot_5.2.pdf)
* [A good blog on gnuplot](http://www.gnuplotting.org/)

## Running tests

Gaston includes an extensive test suite, which can executed with:

```julia
julia> ]test Gaston
```

All tests should pass (but a few may be skipped).

## Support

Please post support questions to [Julia's discuss forum](https://discourse.julialang.org/tag/plotting).

## Contributing

Bug reports, suggestions and pull requests are welcome at [Gaston's github page](https://github.com/mbaz/Gaston.jl)
