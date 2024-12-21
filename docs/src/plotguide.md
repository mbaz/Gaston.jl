# Manual

This manual covers all aspects of using Gaston.

## Gaston Settings

### The terminal

By default, gnuplot chooses an appropriate terminal: `qt` or `wxt` on Linux, `windows` on Windows,
and `aqua` on MacOS.
The terminal can be set by changing the value of `Gaston.config.term`; for example:
```julia
Gaston.config.term = "pngcairo font ',10' size 700,400"
```
To plot the terminals supported by gnuplot, run:
```julia
Gaston.terminals()
```

### Other settings

* `Gaston.config.output`: controls how plots are displayed. Possible values are:
    * `:external`: plots are displayed in GUI windows. This is the default value.
    * `:echo`: sends text-based plots (like `png` and `sixelgd`) back to the terminal. Useful for notebooks and IDEs, and for plotting on the terminal.
    * `:null`: execute all plot commands but do not actually produce a plot.

    If Gaston detects it is running in a notebook environment, it automatically sets the terminal
    to `pngcairo` and `config.output` to `:echo`.
* `Gaston.config.embedhtml`: `Bool`, defaults to `false`. Enables embedding plots in HTML; useful to enable interactivity in Pluto and Jupyter notebooks. See examples in the included Pluto notebooks.

## Plotting

A `plot` command takes three different kinds of arguments: settings, data, and plotline, in that
order.
```julia
plot([settings...], data..., [plotline...])
```
Further curves may be added using `plot!`. (For 3-D plots, use `splot` instead.)

More specifically, a `plot` command takes:
* Zero or more **settings** arguments, which get converted to gnuplot `set` commands.
* One or more **data** arguments, which are written to a file in the format gnuplot expects.
* Zero or more **plotline** arguments, which are appended to gnuplot's `plot` or `splot` commands.

Gaston provides several alternative ways to specify these.

### Settings and Plotlines

All the following are equivalent.

* One single string
```julia
plot("set grid
      unset key
      set title 'A Sinusoid'",
     x, y,
     "with linespoints lc 'green'")
```
* One string per setting
```julia
plot("set grid", "unset key", "set title 'A Sinusoid'",
     x, y,
     "with linespoints", "lc 'green'")
```
* Keywords with `@plot`
```julia
@plot({grid = true, key = false, title = "'A Sinusoid'"},
      x, y,
      {with = "linespoints", lc = "'green'"})
```

Keyword options are enclosed in curly brackets `{}`. To set an option without arguments,
such as `set grid`, use either a lone `grid`, or `grid = true`. To unset an option, such as in
`unset grid`, use ` grid = false`.  Options can be repeated; each one will be converted to a
separate `set` line.

`@plot` also accepts strings, and in fact strings and keywords may be combined:
```julia
@plot({grid, key = false}, "set title 'A Sinusoid'",
      x, y,
      "with linespoints", {lc = "'green'"})
```
It is possible to omit the parenthesis, but in this case the command must fit in a single line.
```julia
@plot {grid, key = false, title = "'A Sinusoid'"} x y {with = "lp", lc = "'green'"}
```
For 3-D plots, use the macro `@splot`.

#### Quoted strings

All strings passed to gnuplot must be enclosed in single quotes, such as in `lc = "'green'"` in the
example above. The `Q` string macro can help reduce the number of quotes needed:
```julia
@plot {grid = true, key = false, title = sqs"A Sinusoid"} x y {with = "lp", lc = Q"green"}
```
This macro turns `"abc"` into `"'abc'"`.

### Data

Data to be plotted can be provided as vectors and/or matrices. Gaston converts the data to a
format compatible with gnuplot. Three cases are supported:
* All data arguments are vectors.
* The first two arguments are vectors of length `n` and `m`, and the third argument is a matrix
  of size `n x m`; further arguments are optional.
* All provided arguments are matrices of size `n x m`.

#### Functions

Functions can be plotted directly, with a given range and number of samples, which
can be specified in the following alternative ways:
```julia
# g is a function
plot(g)            # plots `g` evaluated at 100 samples, from -10 to 9.99
plot((a, b), g)    # plots `g` evaluated at 100 samples, from a to b
plot((a, b, c), g) # plots `g` evaluated at c samples, from a to b
plot(x, g)         # plots g.(x)
```

#### Plot with table

In some cases, it is useful to have gnuplot produce plot data in a "table" format, which can then
be plotted. See an example in [Contour lines on heatmap](@ref). The function `Gaston.plotwithtable`
returns a `Gaston.DataTable` storing the table. All plot commands accept this type.

### Simple themes

Frequently-used settings or plotlines may be stored in a theme; the `@gpkw` macro processes
keyword arguments wrapped in curly brackets.
```julia
theme = @gpkw {grid, key = false}
plot(theme, x, y)
```
Themes may be combined with other themes and/or with strings:
```julia
theme2 = @gpkw {xlabel = Q"X"}
plot(theme, "set title 'A Sinusoid'", theme2, x, y)
```
Themes can also be used for plotlines, and these may also be combined with other themes and/or
strings.
```julia
pltheme = @gpkw {w = "lp", pt = "'o'", ps = 3}
plot(theme, "set title 'A Sinusoid'", theme2, x, y, pltheme)
```
Gaston includes a few generic themes:

|Axis themes | Description |
|-----------:|:------------|
| :notics | Removes all tics |
| :labels | Generic axis labels (`x`, `y`, `z`) |
| :nocb   | Removes colorbox |
| :unitranges | Set all ranges to `[-1:1]` |

For example, the following command plots a sine wave with no tics and generic `x` and `y` axis
labels:
```julia
plot(:notics, :labels, "set title 'Example'", (-1, 1), sin)
```
Themes are also used to provide common plot types (illustrated in the [Themes](@ref) section). The
following are the specialized plot commands and the themes they use:

| Commands | Settings theme | Plotline theme |
|----------|----------------|----------------|
| `scatter`, `scatter!` | `:scatter`, `:scatter3` | `:scatter` |
| `stem`, `stem!` | None | `:stem`, `:impulses` (optional) |
| `bar`, `bar!` | `:boxplot` | `:box` |
| `barerror`, `barerror!` | `:boxerror` | `:box` |
| `histogram` | `:histplot` | `:box`, `:horhist` (1-D); `:image`  (2-D) |
| `imagesc` | `:imagesc` | `:image`, `:rgbimage` |
| `surf`, `surf!` | `:hidden3d` | `:pm3d` |
| `contour` | `:contour` | `:labels` (optional) |
| `surfcontour` | `:contourproj` | `:labels` (optional) |
| `wireframe`, `wireframe!` | `:hidden3d` | None |
| `wiresurf`, `wiresurf!` | `:wiresurf` | None |
| `heatmap` | `:heatmap` | `:pm3d` |

!!! note "Plotline themes"
    Plotline themes must be handled with care: gnuplot requires plotline options
    to be specified in a certain order, may not be repeated, and some combinations are invalid.
    It is very easy to create erroneous plotlines.

!!! note "Gaston is not a gnuplot parser"
    Gaston does not validate that the settings and plotline given to gnuplot are valid. When
    gnuplot returns an error or warning, it is echoed to the terminal.

## Multiplot



## Managing multiple figures

Gaston has the ability to create and manage multiple GUI plot windows simultaneously. Each window
is backed up by its own gnuplot process. The following commands can be used to create and control
multiple windows.

#### Creating and selecting figures

```
Figure()
```
Creates a new, empty figure. All figures are of type `Gaston.Figure`. Gaston keeps internal
references to all figures, to prevent them from being garbage collected.

When creating a figure intended for multiplot, a `multiplot` argument can be provided:
```
Figure(multiplot = "title 'A Multiplot'")
```

When a figure is created, it becomes the active figure, meaning that subsequent plot
commands will go to this figure by default. It is possible to keep figures in different variables:
```
fig1 = Figure()
fig2 = Figure()
```
and then redirect plot commands to the desired figure:
```
plot(fig1, ...)  # plot goes to fig1
plot!(fig2, ...) # new plot added to fig2
```
It is also possible to select figures using _handles_:
```
Figure("density") # figure with handle "density"
Figure(:volume)   # figure with handle :volume
Figure(33)        # figure with handle 33
```
Handles can be of any type. All figures have a handle. By default, handles are
integers in increasing order starting from 1.

The keyword argument `handle` allows specifying the destination of a `plot` command:
```
plot(..., handle = :volume)
plot!(..., handle = 33)
scatter(..., handle = "density")
```

To activate a figure given its handle, use:
```
figure(handle)
```
or, given its index number `i`, use:
```
figure(index = i)
```
With no arguments, `figure()` returns the current figure.

To obtain the list of all current figures and their handles, and to identify the active figure,
use the unexported function `Gaston.listfigures()`.

#### Closing figures

To close the active figure, run
```
closefigure()
```
The figure with handle `h` can be closed with `closefigure(h)`. Likewise, to close figure `f` use `closefigure(f)`. Closing a figure quits the underlying gnuplot process. 

To close all figures, use `closeall()`.

## Saving plots

A plot can be saved to a file in any format supported by gnuplot, with the function
```
save(f ; output, term)
```
where the arguments are:
* `f`, which can be either a `Figure`, or an arbitrary value that is taken to be the handle of the figure to save. Defaults to the active figure.
* `output`, a string that specifies the filename. If empty, it defaults to `figure-` followed by the figure's handle; the filename extension is set to the first three characters of the gnuplot terminal (see next argument).
* `term`, specifies the gnuplot terminal used to save the plot; defaults to `"pngcairo font ',7'"`.

## Interacting with gnuplot

## Defining new plot types and recipes

There are several ways to extend Gaston to create new plot types or to plot
arbitrary types. One is to define a new function that returns a
`Gaston.Figure`. The rest involve extending `Gaston.convert_args` in various
ways.

### Functions that return a `Gaston.Figure`

The first way to extend Gaston to handle arbitrary types is to define a new
function (and optionally new themes) that returns a `Gaston.Figure`.

The recommended way to proceed is to:
0. Define new themes if necessary, by adding key-value pairs to `Gaston.sthemes` and/or
   `Gaston.pthemes`.
2. Process the function arguments as required.
1. Create a new figure inside the function, using either `Figure` or `MultiFigure`.
3. Use `plot` to add new axes and curves to the figure, possibly using the new themes.
4. Return the figure.

### Adding new methods to `Gaston.convert_args`

The function `Gaston.convert_args` is used to convert arbitrary types to something that
gnuplot understands: basically, iterables of numbers, strings or dates. This function
is called with all data and all keyword arguments given to the `plot` command.

For 3-D plot commands such as `splot`, the function `convert_args3` should be used instead.
Note that these functions are not exported.

Both `plot` and `plot!`call `convert_args` behind
the scenes, while both `splot` and `splot!` call `convert_args3`.

There are three kinds of recipes:
* Recipes that return a single curve (`x`, `y`, and a plotline).
* Recipes that return a whole axis (settings and curve(s)).
* Recipes that generate a multiplot (mulitplot settings and an array of axes).

#### Recipes that return a single curve

This kind of recipe returns a `Plot` object, which includes data along with a
plotline specification. The following example illustrates the process:

```julia
import Gaston: convert_args, Plot

# add method to convert_args
function convert_args(d::Data1, args... ; pl = "", kwargs...)
    x = 1:length(data.samples)
    y = data.samples
    Plot(x, y, pl)  # return a Plot
end

plot(data)   # plot
plot!(data)  # also works
```

#### Recipes that return a new axis

A recipe may also return an entire `Axis` object, with its own settings and
curves. The following example illustrates returning an axis with two curves.

```julia
import Gaston: convert_args, Plot, Axis

struct Data2 end

function convert_args(x::Data2, args... ; kwargs...)
    x = range(0, 1, 100)
    p1 = Plot(x, cos.(4x), "dt '-' lc 'red' t 'cosine'")
    p2 = Plot(x, sin.(5x), "dt '.' lc 'blue' t 'sine'")
    Axis("set grid\nset title 'Full axis recipe'", [p1, p2])  ## return an Axis
end

plot(Data2())
```

#### Recipes to generate multiplots

Finally, a recipe can also generate a full multiplot, with multiple axes. In this case, the
recipe must return a `NamedTuple` with the following fields:
* `axes`, a vector of `Axis`.
* `mp_settings`, a string with gnuplot's multiplot settings.
* `is_mp`, a boolean, `true` if the length of `axes` is larger than 1.
* `mp_auto`, a boolean to turn on automatic layout.

Here's an example, creating a figure with four axes and automatic layout.

```julia
import Gaston: Plot, Axis, Axis3, convert_args
closeall() # hide

struct MyType end

function convert_args(x::MyType)
    t1 = range(0, 1, 40)
    t2 = range(-5, 5, 50)
    z = Gaston.meshgrid(t2, t2, (x,y) -> cos(x)*cos(y))
    @gpkw a1 = Axis({title = Q"First Axis"}, [Plot(1:10, rand(10))])
    @gpkw a2 = Axis({title = Q"Trig"}, [Plot(t1, sin.(5t1), {lc = Q"black"}),
                                        Plot(t1, cos.(5t1), {w = "p", pt = 16})])
    @gpkw a3 = Axis3({title = Q"Surface", tics = false, palette = (:matter, :reverse)},
                     [Plot(t2, t2, z, {w = "pm3d"})])
    @gpkw a4 = Axis({tics, title = false, title = Q"Last Axis"},
                    [Plot(1:10, 1:10, rand(10,10), "w image")])
    # return named tuple with four axes
    (axes = [a1, a2, a3, a4],
     mp_settings = "title 'A Four-Axes Recipe' layout 2,2",
     is_mp = true,
     mp_auto = false)
end

plot(MyType())
```
