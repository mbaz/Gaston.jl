```@meta
Author = "Miguel Bazdresch"
```

# Gaston.jl

[Gaston](https://github.com/mbaz/Gaston.jl) is a Julia package for plotting. It provides an interface to [gnuplot](http://www.gnuplot.info), a mature and powerful plotting package available on all major platforms.

```@example t2
using Gaston, SpecialFunctions
set(reset=true) # hide
set(mode="ijulia")  # hide
set(size="500,400")  # hide
set(font="Consolas 9")  # hide
gp = """set view 45,45;
        set pm3d lighting primary .5 specular .4
        unset key"""
x = y = 0:0.075:10;
surf(x, y, (x,y) -> besselj0(y)*x^2,
     plotstyle = :pm3d,
     gpcom = gp)
```

(Image inspired by [What's new in gnuplot 5.2?](https://lwn.net/Articles/723818/))

## Package features

Why use Gaston, when there are modern, powerful alternatives such as [Plots.jl](https://github.com/JuliaPlots/Plots.jl) and [MakiE.jl](https://github.com/JuliaPlots/Makie.jl)? These are some Gaston features that may be attractive to you:

* Gaston can plot:
    * Using graphical windows, and keeping multiple plots active at a time, with mouse interaction
    * Directly to the REPL, using text (ASCII) or [sixels](https://en.wikipedia.org/wiki/Sixel)
    * In Jupyter (using IJulia.jl) and Juno
* Supports popular 2-D plots: regular function plots, stem, step, histograms, images, etc.
* Supports surface, contour and heatmap 3-D plots.
* Can save plots to multiple formats, including pdf, png and svg.
* Can export plots for integration into Latex documents, using the document's fonts.
* Provides a simple interface for knowledgeable users to access gnuplot features not exposed by Gaston.
* Fast: time to load package, plot, and save to pdf is around five seconds.

Gaston's philosophy is that plotting to the screen should be fast and non-ugly. Publication-quality plots are the domain of TiKZ and pgfplots.

Knowledge of gnuplot is not required. Users familiar with gnuplot, however, will be able to take advantage of Gaston's facilities to access the (vast) feature set not directly exposed by Gaston.

In a sense, Gaston can be seen as a translator of plotting commands, given in conventional Matlab and matplotlib stye, to gnuplot. Gaston also allows direct communication with gnuplot for those cases where it doesn't provide translation support.

## Installation

Gaston supports Julia version 1.x, and requires Gnuplot version 5.0 or above (version 5.2.8 is recommended). To install Gaston from the Julia REPL, run

```julia
julia> ]add Gaston
```

Typing `]` switches the Julia REPL to the package manager, and the `add` command installs the package. To exit the package manager, hit the backspace key.

### gnuplot configuration

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

Simple plots can be generated with the `plot` command:

```julia
plot(1:10,
     title="A simple plot")
```

Several examples of different plotting types are given in the Examples section below.

The [Introduction to plotting](@ref) has more information on how to use the plot commands, and how to configure Gaston.

The sections [2-D Examples](@ref) and [3-D Examples](@ref) show many plotting examples.

The [Settings and Configuration](@ref) section includes a list of all available configuration options.

The [Usage notes and FAQ](@ref) section includes additional usage examples and answers frequent questions.

## Running tests

Gaston includes an extensive test suite, which you can execute with:

```julia
julia> ]test Gaston
```

All tests should pass.

## Compatibility notes

Gaston is developed in Linux, and that is where it is better supported. However, running in Julia means that it is mostly compatible with any system where Julia runs. Some known differences are listed below.

### A note on Windows

Gaston runs on Windows and care is taken that all tests pass. However, currently stream communication (which Gaston relies on) is very slow in Windows; so, you can expect some plot commands to take a few seconds to complete. See [this thread on Discourse](https://discourse.julialang.org/t/standard-streams-much-slower-in-windows-than-in-linux/24924) for more information.

### A note on OS X

Recent versions of OSX removed support for the aqua terminal from gnuplot. Before attempting to use aqua in Gaston, open a terminal and run this command:

```julia
$ gnuplot -e "set term" | grep aqua
```

If nothing is printed, then you do not have support for the aqua terminal and should not attempt to use it in Gaston. By default, Gaston uses the `qt` terminal. You can verify if your version of gnuplot supports it by issuing

```julia
gnuplot -e "set term" | grep qt
```

A further alternative is to revert to the `x11` terminal with:

```julia
set(terminal="x11")
```

`x11` is a fallback terminal with less bells and whistles than `qt`, `wxt` or `aqua`, but which runs essentially everywhere x11 runs.

## Support for Julia v0.6

The current version of Gaston requires Julia 1.x. The last version of Gaston that is compatible with Julia v0.6 is 0.7.4. Note that this version of Gaston is unsupported.

## Bloat watch

The number of lines includes comments and empty lines.

```@example t2
tics = """set xtics rotate ("0.1" 1, "0.2" 2, "0.3" 3, "0.4" 4, "0.5.1" 5, "0.5.2" 6, "0.5.3" 7, "0.5.4" 8, "0.5.5" 9, "0.5.6" 10, "0.5.7" 11, "0.6" 12, "0.7" 13, "0.7.1" 14, "0.7.2" 15, "0.7.3" 16, "0.7.4" 17, "0.9.0" 18, "0.9.1" 19, "0.9.2" 20, "0.10.0" 21, "0.11.0" 22)"""
lc=[754,836,1196,1575,2301,2301,2343,2342,2352,2262,2262,2297,1314,1318,1362,1363,1424,1488,1382,1418,1417,1703]
bar(lc,xlabel="Gaston version",ylabel="Lines of code",
    boxwidth="0.8 relative", linecolor="turquoise",
    title="Bloat Watch",gpcom=tics)
```
