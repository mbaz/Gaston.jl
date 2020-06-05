```@meta
Author = "Miguel Bazdresch"
```

# Introduction to plotting

Gaston supports essentially all 2-D plots styles that gnuplot is capable of, including regular function plots, plots with logarithmic axes, scatter, stem and step plots, bar plots and histograms, images, etcetera.

It can also create 3-D plots, including wireframe, surface, scatter and contour plots.

This section presents the basic usage of `plot` and `plot!`. Examples of specific plot types, such as cloud points, stem plots, and images, are presented in [2-D plotting tutorial](@ref twodeetut). For 3-D plots, see [3-D plotting tutorial](@ref threedeetut).

## `plot` and `plot!` commands

The main 2-D plotting commands are `plot` and `plot!`. To plot a vector `y` against a vector `x`, use `plot(x,y)`:

```@example intro
using Gaston # hide
set(reset=true) # hide
set(termopts="size 550,325 font 'Consolas,11'") # hide
t = 0:0.01:1
plot(t, sin.(2π*5*t),
     linecolor  = :coral,
     Axes(title = :First_Plot)
     )
```

To add a second curve, use `plot!`:

```@example intro
plot!(t, cos.(2π*5*t),
      plotstyle = "linespoints",
      pointtype = "ecircle",
      linecolor = "'blue'")
```

Curves are added to a figure one by one; the first curve is plotted with `plot`, and the rest with succesive `plot!` commands.

The commands `plot` and `plot!` take three kinds of arguments:
* Data, in the form of vectors `x`, `y`, etcetera.
* Configuration related to the data's appearance: line color, line width, markers, line style, etcetera. These are passed to `plot` as regular arguments (for example, `linecolor = :coral` above).
* Configuration related to the entire figure: title, tics, ranges, grid, etcetera. These must be wrapped in `Axes()`; for example, `Axes(title = :First_Plot)`. Only `plot` accepts these arguments.

## Figure and curve configuration

An example can be worth a thousand words. The following commands are all exactly equivalent:

```julia
plot(t, sin.(2π*5*t),
     with       = "linespoints",
     linecolor  = :coral,
     Axes(title = :First_Plot,
          xtics = "(0.25, 0.5, 0.75)")
     )
```

```julia
plot(t, sin.(2π*5*t),
     curveconf = "with linespoints linecolor 'coral'",
     Axes(title = :First_Plot,
          xtics = "(0.25, 0.5, 0.75)")
     )
```

```julia
A = Axes(title = :First_Plot, xtics = "(0.25, 0.5, 0.75)")
plot(t, sin.(2π*5*t), A,
     plotstyle = :linespoints,
     lc  = "'coral'"
    )
```

```julia
plot(t, sin.(2π*5*t),
     curveconf = "w lp lc 'coral'",
     Axes(axesconf = """set title 'First Plot'
                        set xtics (0.25, 0.5, 0.75)""")
    )
```

```julia
plot(t, sin.(2π*5*t),
     curveconf = "w lp lc 'coral'",
     Axes(axesconf = "set title 'First Plot'",
          xtics = "(0.25, 0.5, 0.75)")
    )
```

## How arguments are handled

Gaston has a few rules to handle arguments, and supports special syntax to make passing commands to gnuplot more convenient. All configuration commands are given as key-value arguments.

* Values can be given in quotes (`"'red'"`) or as symbols (`:red`).
* Values in quotes are passed directly to gnuplot.
* Symbol values are passed to gnuplot wrapped in single quotes. For example, `linecolor = :blue` in the example above is translated as `linecolor 'blue'`.
* In symbols, underscores are converted to spaces. For example, `title = :First_Plot` is translated as `set title 'First Plot'`.
* When an argument is a vector, each element is handled as a separate argument. For example, `xtics = [1:2:5, "reverse"]` is translated to two separate gnuplot commands, `set xtics 1, 2, 5` and `set xtics reverse`.
* To send a `set` command without options, like `set grid`, use (for example) `grid = :on` (or `"on"`, or `true`).
* To send an `unset` command, use (for example) `tics = :off` (or `"off"`, or `false`).

!!! info "Interaction with gnuplot"
    Keyword arguments wrapped in `Axes()` are converted to gnuplot `set` commands. For example,

        Axes(pm3d = "lighting primary 0.5")

    is sent to gnuplot as

        set pm3d lighting primary 0.5

    Other keyword arguments are used as plot elements; for example,

        w = :lp, u = "1:3"

    is sent to gnuplot as

        plot 'filename' w lp u 1:3

## Configuring a figure's appearance

As explained above, a figure's configuration is given as key-value pairs wrapped in `Axes()`. Some arguments have special syntax for convenience:

* The `axis` argument sets the axis type:
    * `axis = "semilogx"` →  `set logscale x`
    * `axis = "semilogy"` →  `set logscale y`
    * `axis = "semilogz"` →  `set logscale z`
    * `axis = "loglog"` →  `set logscale xyz`

* Tics are set with `xtics`, `ytics`, `ztics` or `tics`:
    * `tics = a:b:c` →  `set tics a, b, c`
    * `tics = (a:b:c, ["l1" "l2" ... "lN"])`  →  `set tics ("l1", a, ..., "lN", c)`
    * `tics = ([t1 t2 ... tN], ["l1" "l2" ... "lN"])`  →  `set tics ("l1", t1, ..., "lN", tN)`

In the last two cases, the first element in the tuple represents the numerical tics, and the second element is the set of labels.

Example:
```@example intro
plot(t, sin.(2π*5*t),
     linecolor  = :coral,
     Axes(title = "'Tics Example'",
          xtics = [(0.25:0.5:1, ["1/4" "3/4"]), "rotate"])
    )
```

* Ranges are specified with `xrange`, `yrange`, `zrange` or `cbrange`:
    * `{x,y,z,cb}range = (low, high)` → `set {x,y,z,cb}range [low|high]`
    * `{x,y,z,cb}range = (-Inf, high)` → `set {x,y,z,cb}range [*|high]`
    * `{x,y,z,cb}range = (low, Inf)` → `set {x,y,z,cb}range [low|*]`

Example:
```@example intro
plot(t, sin.(2π*5*t),
     linecolor  = :coral,
     Axes(title = :Range_Example,
          yrange = (-Inf, 2))
    )
```

* A set of linetypes with the colors specified by a palette from [ColorSchemes.jl](https://github.com/JuliaGraphics/ColorSchemes.jl). The palette name must be specified as a symbol. For example,

```@example intro
t = range(-2, 2, length = 100)
f(t, σ) = exp.(-σ*abs.(t))
A = Axes(title = :Linetypes_Example, linetype = :sunset)
plot(t, f(t,0.5), lw = 3, A)
plot!(t, f(t, 1), lw = 3)
plot!(t, f(t, 1.5), lw = 3)
plot!(t, f(t, 2), lw = 3)
plot!(t, f(t, 2.5), lw = 3)
```

* A string containing gnuplot commands may be passed as argument `axesconf`. This string is sent to gnuplot without modification.

* In addition, a string of gnuplot commands may be specified using Gaston's configuration setting `preamble`. This string will be used in all subsequent plots, before the commands specified in `Axes()`. This may be useful to configure gnuplot in environments where it is not feasible to have a permanent gnuplot configuration file. For example,

```julia
set(preamble = "set offsets graph .05, graph .05, graph .05, graph .05")
```

## Configuring a curve's appearance

All key-value arguments provided to `plot` and not wrapped in `Axes()` are interpreted as a curve configuration. Some of them have offer some convenient syntax:

* The plot style can be specified with the `with` key. The keys `with`, `w` and `plotstyle` are synonyms.

* The point type is specified with the key `pointtype`. This key is synonym with `pt` and `marker`. Gnuplot accepts markers specified as numbers. In addition, Gaston accepts the following descriptive strings:
| Value | Meaning |
|-------|---------|
| `"dot"` | Single pixel |
| `"+"` | A plus sign|
| `"x"` | A cross |
| `"*"` | An asterisk|
| `"ecircle"` | Empty circle |
| `"fcircle"` | Full circle |
| `"esquare"` | Empty square |
| `"fsquare"` | Full square |
| `"etrianup"` | Empty up triangle |
| `"ftrianup"` | Full up triangle |
| `"etriandn"` | Empty down triangle |
| `"ftriandn"` | Full down triangle |
| `"edmd"` | Empty diamond |
| `"fdmd"` | Full diamond |
Other strings are passed to gnuplot wrapped in single quotes; for example, `pt = "λ"` is translated as `pointtype 'λ'`.

* A legend can be specified with the keys `legend`, `leg`, `title` or `t`.

* A full plot specification can be provided with the key `curveconf`. This overrides all other provided arguments. For example, this plot

```julia
t = 0:0.05:10pi
plot(t, cos, w=:lp, leg = :A_sine_wave, marker = "fdmd", pi = -20)
```

can equivalently be specified as:
```julia
cc = "w lp t 'A sine wave' pt 13 pi -20"
plot(t, cos, curveconf = cc)
```

## Data arguments

Most plotting commands accept data in a few different formats:

* `plot(y, args...)` assumes that `x = 1:length(y)`
* `plot(x, f::Function, args...)` applies function `f` to `x`.
* `plot(c, args...)` where `c` is complex, plots `real(c)` vs `imag(c)`.

In addition, gnuplot may use additional data to, for example, set a marker's size or color. These are called "supplementary data" by Gaston, and are provided to `plot` using the `supp` keyword argument. For example,

```@example intro
c = rand(30) .+ im*rand(30)
plot(c, supp = 3abs.(c), w = :p, marker = "ecircle", markersize = "variable")
```

## 3-D plotting

Gaston and gnuplot are fully capable of plotting surfaces and other kinds of 3-D plots such as contours and heatmaps. See the [3-D plotting tutorial](@ref threedeetut).

## Multiplot

Multiple plots can be included in the same figure. This is accomplished by calling `plot` with a matrix made up of other figures. If a matrix elements is `nothing`, then the corresponding subplot is left empty. An example:

```@example intro
t = 0.01:0.01:10pi
p1 = plot(t, cos, Axes(title = :Plot_1), handle = 1)
p2 = plot(t, t.^2, Axes(title = :Plot_2), handle = 2)
p4 = plot(t, exp.(-t), Axes(title = :Plot_4), handle = 4)
plot([p1 p2 ; nothing p4])
```

The `handle` argument is necessary because a `plot` command, by default, overwrites the previous plot. See the section on [Managing multiple figures](@ref) for more details on how handles work.

## Saving plots

To save a plot (or "print" it, in gnuplot's parlance), use the `save` command, which requires `term` and `output` arguments. Optionally, arguments specifying the `font`, `size`, `linewidth`, and `background` color may be given. These may be specified in a gnuplot command string with `saveopts`, which may also be specified in advance using `set(saveopts = "...")`. The following two examples are equivalent:

```julia
save(term = "png",
     output= "myfigure.png",
     font = "Consolas,10",
     size = "1280,900",
     linewidth = 1,
     background = "blue")
```

```julia
save(term = "png", output = "myfigure.png",
     saveopts = "font 'Consolas,10' size 1280,900 lw 1 background 'blue'")
```
