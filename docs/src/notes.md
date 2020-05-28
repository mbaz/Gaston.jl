# Usage notes and FAQ

## How to keep multiple plots (figures) on screen at a time?

When using the graphical terminals `qt`, `wxt`, `aqua` (on Mac) or `x11`, Gaston can keep an unlimited number of "figures" open on screen at the same time. Each figure is identified by a unique handle; handles are integers larger than 0.

The following commands are provided to help create, select and close figures:

* `figure()`: creates a new figure with the smallest available handle; returns the handle number.
* `figure(h)`: if a figure with handle `h` exists, select it; otherwise, create it.
* `closefigure()`: close and delete the most recently used figure.
* `closefigure(h)`: close and delete figure with handle `h`.
* `closeall()`: close all figures.

All plot commands take a handle as optional argument to indicate the figure where the plot action will be taken. As an example, assume there are three figures with handles `1`, `2` and `3`. Then, the command

```julia
plot!(y, handle=2)
```

will append a curve to the figure with handle `2`.

Gnuplot provides basic mouse interaction for graphical terminals, like zooming and annotating coordinates. This only works on the active figure, which is either the last figure plotted, or the one selected with a `figure(h)` command. Continuing the previous example, the `plot!` command made `2` the active figure. If mouse interactivity were desired in figure `3`, then we'd need to run `figure(3)` to make it active.

## How does Gaston handle missing `x` values?

If only one vector `y` is given, then its indices are used for the `x` axis.

## I run `plot` inside a `for` loop and no plots are produced! (or: Julia's display system)

Julia separates the calculation of a result from the display of the result (see [custom pretty-printing](https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing-1) and [multimedia I/O](https://docs.julialang.org/en/v1/base/io-network/#Multimedia-I/O-1) in Julia's documentation). This mechanism is very powerful; in Gaston, it enables plotting to the REPL, Jupyter, Juno, or in Documenter.jl with just a few lines of code. In other words, plotting is not a side effect of running `plot`, the way it is in, say, Matlab; rather, a plot is produced when a result of type `Gaston.Figure` is returned by some code.

While elegant and powerful, this mechanism can also be surprising if you're used to side-effect plotting. None of the following code samples display any plots:

```julia
y = rand(20)
plot(y);  # note the final ; suppreses displaying the result
```

```julia
# nothing is returned by the for loop
for k = 1:5
    plot(k*y)
end
```

```julia
# function that does not return a figure
function f(y)
    plot(sin.(y))
    println("Sum = $(sum(y))")
end
```

The common problem in the code samples above is that a figure is never returned; in consequence, no figure is displayed. This can be fixed by making sure your code returns a figure; or alternatively, save the figure in a variable and display it when it is convenient. For example:

```julia
p = Gaston.Figure[]
for k = 1:5
    push!(p, plot(k*y))
end
```

Now, `p[3]` returns the third plot (for example). Another way to force the figure to be rendered is to call `display()`:

```julia
# all five figures are displayed
closeall()
for k = 1:5
    figure()
    display(plot(k*y))
end
```

## How to set the tics

Gnuplot's tics functionality is flexible and somewhat complex, and I haven't yet found the best way to expose it. For the moment, tics can be set using the `gpcom` plot argument; see an example here: [Bar plots](@ref).

## Error handling

Gnuplot's main drawback, from a usability standpoint, is that it is not a library; it is designed to be used interactively. Gaston simulates a user typing interactive commands in a gnuplot session. Gaston goes to some lengths to prevent providing gnuplot with invalid inputs; however, preventing this completely would require re-implementing gnuplot's parser in Gaston.

An example of an error caught by Gaston:

```julia
julia> y = rand(20)
julia> plot(y,plotstyle="linepoints")  # missing an 's'

ERROR: DomainError with linepoints:
supported 2-D plotstyles are: ["", "lines", "linespoints", "points", "impulses", "boxes", "errorlines", "errorbars", "dots", "steps", "fsteps", "fillsteps", "financebars"]
```

An example of an error returned by gnuplot:

```julia
julia> plot(y,linecolor="thecolorofsunset")
┌ Warning: Gnuplot returned an error message:
│
│ gnuplot> plot '/tmp/gaston-cX8CoMqR-10'  i 0 lc rgb 'thecolorofsunset' lw 1
│                                                                        ^
│          line 0: unrecognized color name and not a string "#AARRGGBB" or "0xAARRGGBB"
│
│ )
└ @ Gaston gaston_llplot.jl:199
```

Gaston does its best effort to read and display any warnings or errors produced by gnuplot, and to recover gracefully. In some corner cases, it might happen that the communication link enters an unforeseen state and a restart is required. Please file a Gaston issue if you experience this.

## What is Gaston's roadmap?

* Modernize its syntax, using `Plots.jl` and `MakiE` as inspiration.
* Support for exporting to TiKZ and/or PGFPlots.
* Expose more of gnuplot's functionality: tics, quiver plots, etc...

## Contributing

Issues and pull requests are welcome at [Gaston's github page](https://github.com/mbaz/Gaston.jl)
