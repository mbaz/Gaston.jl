# Examples

The plots below have been rendered in a png terminal with the following configuration:
```julia
Gaston.config.term = "pngcairo font ',10' size 640,480"
```
In addition, gnuplot's start up file is as described in the Introduction: [Gnuplot startup file](@ref).

## 2-D Plots

```@setup 2dt
using Gaston
Gaston.config.output = :echo
Gaston.config.term = "pngcairo font ',10' size 640,480"
closeall() # hide
```

Let us start with a simple sine wave plot:

```@example 2dt
x = range(0, 0.5, length = 100)
y = sin.(2*pi*10*x)
plot(x, y)
```
Now, let us add a grid and some annotations:
```@example 2dt
@plot {grid, title = Q"{/:Bold A sine wave}", xlabel = Q"Time", ylabel = Q"Volts"} x y
```
Here we have used `@plot` instead of `plot`, which allows us to specify the plot settings
as a list of keyword arguments. These arguments can be stored in a "theme" using `@gpkw`:
```julia
settings = @gpkw {grid, title = Q"{/:Bold A sine wave}", xlabel = Q"Time", ylabel = Q"Volts"}
```
In addition, we have used the `Q` string macro to avoid typing single quotes; `Q"Time"` is
converted to `"'Time'"`.

Now let us change the line color and markers:
```@example 2dt
settings = @gpkw {grid, title = Q"A sine wave", xlabel = Q"Time", ylabel = Q"Volts"}; # hide
@plot settings x y {with = "lp", lc = Q"sea-green", pt = :fcircle, ps = 1.5}
```
Parameters that affect how the curve is plotted are specified *after* the data. These
can also be stored and reused, so that
```julia
plotline = @gpkw {with = "lp", lc = Q"sea-green", pt = :fcircle, ps = 2}
@plot settings x y plotline
```
would produce the same plot. Settings and plotline parameters can also be specified as strings;
see the [Manual](@ref) for all the details. Gaston also has a number of built-in [Themes](@ref).

Use `plot!` or `@plot!` to plot a second curve:
```@example 2dt
plotline = @gpkw {with = "lp", lc = Q"sea-green", pt = :fcircle, ps = 2} # hide
@plot(settings,
      {title = Q"Two sinusoids", key = "columns 1", key = "box outside right top"},
      x, y,
      plotline, {title = "'sin'"})
y2 = cos.(2*pi*10*x)
@plot! x y2 {dashtype = Q".-.", title = Q"cos"}
```
Here we see how multiple settings and plotline arguments can be combined. 
Note that new settings cannot be declared in `plot!` commands; only the plotline for the new curve can be
specified.

#### Plotting functions

In the examples above, the data given to `plot` is stored in vectors. Functions can be plotted
directly, with a given range and number of samples, as follows:
```@example 2dt
g(x) = exp(-abs(x/5))*cos(x)
tt = "set title 'g = x -> exp(-abs(x/5))*cos(x))'"
plot(tt, (-10, 10, 200), g) # plot from x = -10 to 10, using 200 samples
```
Ranges can be specified in the following alternative ways:
```julia
plot(g)            # 100 samples, from -10 to 9.99
plot((a, b), g)    # 100 samples, from a to b
plot((a, b, c), g) # c samples, from a to b
plot(x, g)         # plot g.(x)
```

#### Multiplots

To plot multiple sets of axes in a single figure, we use indexing into the figure as follows:
```@example 2dt
f = plot(x, y) # f is of type Gaston.Figure
plot(f[2], x, sinc.(10x))
```
It is possible to have empty "slots":
```@example 2dt
plot(f[4], x, sinc.(20x), "w lp pn 12")
```
Gaston tries to keep a square figure aspect ratio as more and more axes are included. 
Add another plot to a subplot using indexing:
```@example 2dt
plot!(f[2], x, 0.3randn(length(x)))
```
To gain full control of gnuplot's multiplot options, instantiate a
new `Gaston.Figure` with the string keyword argument `multiplot`; the string is passed to
gnuplot's `set multiplot`:
```@example 2dt
closeall() # hide
f = Figure(multiplot = "title 'Arbitrary multiplot layout demo'")
x = randn(100)
y = randn(100)
@plot({margins = (0.1, 0.65, 0.1, 0.65)},
      x, y,
      "w p pt '+' lc 'dark-green'")
@gpkw histogram(f[2],
                {margins = (0.7, 0.95, 0.1, 0.65), tics = false},
                y,
                {lc = Q"dark-green"}, nbins = 10, horizontal = true)
@gpkw histogram(f[3],
                {margins = (0.1, 0.65, 0.7, 0.9), boxwidth = "1 relative"},
                x,
                {lc = Q"dark-green"}, nbins = 10)
```
Note that margins can be specified as a tuple. The macro `@gpkw` allows us to use keyword
settings in the `histogram` plot command (described below).

The figure's `multiplot` field can be modified *post-hoc*:
```julia
f.multiplot = "title 'New title' layout 2,2"
```
!!! info
    Gaston takes care of the multiplot layout automatically **only** if the figure's `multiplot`
    setting is an empty string (this is the default value). If it's not empty, then the user
    is in charge of handling the layout.

!!! info
    Gaston never clears a figure's `multiplot` setting. If re-using a figure for subsequent
    plots, this setting must be adjusted manually.

## 3-D Plots
Plotting in 3-D is similar to 2-D, except that `splot` (and `@splot`, `splot!`, `@splot!`) are used
instead of `plot`. This example shows how to plot the surface defined by function `s`:
```@example 2dt
x = y = -15:0.2:15
s = (x,y) -> @. sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
@splot("set title 'Sombrero'\nset hidden3d", {palette = :cool}, x, y, s, "w pm3d")
```
The palette `cool` is defined in [ColorSchemes](https://github.com/JuliaGraphics/ColorSchemes.jl).

## Animations

Animations require use of the `gif` or `webp` terminals (make sure your
notebook supports the `image/webp` MIME type before using it).

Creating an animation is similar to multiplotting: multiple axes are drawn on
the same figure. When using the `animate` option of the `gif` or `webp`
terminals, however, the plot is rendered as an animation.

Note that gnuplot will output a message to `STDERR` indicating how many frames
were recorded; this message is purely informative and not actually an error.

A difficulty arises when mixing plot formats in a notbook (say, `png` and
`gif`): the terminal is specified in the configuration variable `Gaston.config.term`.
However, some notebook programs (such as Pluto) execute cells in arbitrary
order. This means that changing the terminal in one cell may affect other
cells.

To solve this problem, Gaston provides a way to ignore the global terminal
configuration when rendering a plot. A figure `f` can be rendered with a given
terminal by calling `animate(f, term)`. The default value of `term` is stored
in `Gaston.config.altterm` and defaults to `gif animate loop 0`.

The following examples illustrate how to create and display animations, in this case with a
background image:
```@example 2dt
f = Figure()  # new, empty figure
frames = 75
x_bckgnd = range(-1, 1, 200)  # x values for the background image
bckgnd = Plot(x_bckgnd, sin.(2π*2*x_bckgnd), "lc 'black'")  # background image
x = range(-1, 1, frames)
for i in 1:frames
    plot(f[i], x[i], sin(2π*2*x[i]), "w p lc 'orange' pt 7 ps 7") # first plot the function...
    push!(f[i], bckgnd)  # ... then add the background
end
for i in frames:-1:1  # in reverse
    plot(f[2frames-i+1], x[i], sin(2π*2*x[i]), "w p lc 'orange' pt 7 ps 7")
    push!(f[2frames-i+1], bckgnd)
end
save(f, output = "2DAnim.webp", term = "webp animate loop 0 size 640,480")
```
![An animation](2DAnim.webp)

## Themes

Gaston includes several themes for common plot styles. The easiest way to use
them is through the specialized plot commands described below. For more
details, see the [Manual](@ref).

Themes are divided into _settings themes_, which specify gnuplot `set` commands,
and _plotline themes_, which specify how a particular curve is displayed
(color, thickness, etc.) Settings themes are stored in the dictionary
`Gaston.sthemes`, and plotline themes are stored in `Gaston.pthemes`. The
themed commands described below use combinations of these themes to create a
specific type of plot.

In gnuplot, plotlines (as in `plot with lines`) are especially difficult to
theme, because repeated options are errors, and options given in the wrong
order may also cause errors. As an example, consider using `scatter` to plot
some points; we want to use `pointtype` number 4:
```julia
scatter(rand(10), rand(10), "pointtype = 4")
```
This command causes an error because the plotline theme `:scatter` already
specifies the pointtype! To plot a scatter plot using the desired point type,
use plain `plot` with the appropriate settings, create your own theme, or
modify the built-in theme. Here is an example where the theme is modified.
First find out how the theme is set up:
```@example 2dt
Gaston.pthemes[:scatter]
```
Then, modify the entry for the pointtype:
```@example 2dt
Gaston.pthemes[:scatter][2] = "pointtype" => 4
scatter("set title 'Scatter plot with modified theme", rand(10), rand(10), "lc 'dark-green'")
```
Note how the linecolor was specified without causing an error, since it is not included in the theme.

#### Scatter plots

| command | settings theme | plotline theme |
|:--------|:---------------|:---------------|
|`scatter` | none | `:scatter` |
|`scatter3` | `:scatter3` | `:scatter` |

```@example 2dt
# reset theme # hide
@gpkw Gaston.pthemes[:scatter] = {with = "points", pointtype = :fcircle, pointsize = 1.5} # hide
xg = randn(20)
yg = randn(20)
scatter("set title 'Scatter plot'
         set key outside",
        xg, yg,
        "title 'gaussian'")
xu = rand(20)
yu = rand(20)
scatter!(xu, yu, "title 'uniform'")
```
A 3-D scatter plot (the default settings theme (`:scatter3`) draws all the borders):
```@example 2dt
scatter3("set title 'A 3-D scatter plot", randn(10), randn(10), randn(10))
```

#### Stem plots

| command | settings theme | plotline theme |
|:--------|:---------------|:---------------|
|`stem` | none | `:stem`, `:impulses` |

Stem plots are often used in digital signal processing applications to represent
a discrete-time (sampled) signal.
```@example 2dt
stem("set title 'Stem plot'", g)
```
To generate a stem plot, gnuplot actually plots twice: once with style `impulses` and once with
`points` (set to empty circles). Normally, each of these plots would have a different color. To
use the same color for both, use the `color` keyword argument:
```@example 2dt
stem("set title 'Stem plot'", g, color = "'goldenrod'")
```
The circular marks can be omitted with the `onlyimpulses` keyword argument:
```@example 2dt
stem("set title 'Stem plot with onlyimpulses'", g, onlyimpulses = true)
```

#### Bar plots

| command | settings theme | plotline theme |
|:--------|:---------------|:---------------|
|`bar` | `:boxplot` | `:box` |
|`barerror` | `:boxerror` | `:box` |

```@example 2dt
bar("set title 'Bar plot'", rand(10), "lc 'turquoise'")
```
This example shows how to plot two sets of bars, using `bar!`:
```@example 2dt
bar("set title 'Two bar plots'", rand(10), "lc 'dark-violet'")
bar!(1.5:10.5, 0.5*rand(10), "lc 'plum' fill pattern 4")
```
Error bars are handled by `barerror`; there is also `barerror!`.
```@example 2dt
barerror("set title 'Error bars plot'", 1:10, rand(10), 0.1*rand(10).+0.1, "lc 'sandybrown'")
```

#### Histograms

| command | settings theme | plotline theme |
|:--------|:---------------|:---------------|
|`histogram` | `:histplot` | `:box`, `:horhist` (1-D); `:image`  (2-D) |

The `histogram` function takes these optional keyword arguments:
* `nbins`: specifies the number of bins. Defaults to 10.
* `mode::Symbol`: Controls histogram normalization mode; passed to
  [`StatsBase.normalize`](https://juliastats.org/StatsBase.jl/stable/empirical/#LinearAlgebra.normalize).
  Defaults to `:none`.
* `edges`: a vector or a range specifying the bin edges; if specified, takes
  precedence over `nbins`. Defaults to `nothing`.
* `horizontal::Bool`: if `true`, the histogram is drawn horizontally. Defaults
  to `false`.
`histogram` uses the settings theme `:histplot`, and plotline themes `:box` or `:horhist`.
2-D histograms are supported, by passing two datasets.

Using `nbins`:
```@example 2dt
histogram("set title 'Histogram (nbins)'",
          randn(10_000),
          nbins = 20, mode = :pdf)
```

Using `edges`:
```@example 2dt
histogram("set title 'Histogram (edges)'",
          0.75*randn(10_000),
          edges = -2:0.75:3, "lc 'dark-khaki'")
```

A horizontal histogram:
```@example 2dt
histogram("set title 'horizontal histogram'",
          rand(1000),
          nbins = 15, horizontal = true, "lc 'orchid'")
```

In the case of 2-D histograms, `nbins` or `egdes` may be a tuple; otherwise, both axes use the
same settings. The plotline theme is `:image`.
```@example 2dt
x = 2.5*randn(100_000)
y = 2.5*randn(100_000)
th = @gpkw {palette = :matter, colorbox = false, title = Q"2-D histogram",
            xrange = (-10, 10), yrange = (-10, 10)}
histogram(th, x, y, nbins = 50, mode = :pdf)
```

#### Images

| command | settings theme | plotline theme |
|:--------|:---------------|:---------------|
|`imagesc` | `:imagesc` | `:image`, `:rgbimage` |

Arrays may be plotted as images using `imagesc`. Note that, in contrast to other plotting packages,
the first row is plotted at the top.
```@example 2dt
X = [0 1 2 3;
     0 3 2 1;
     0 2 2 0;
     3 0 0 0]
imagesc("unset xtics\nunset ytics", X)
```
To display the image as grayscale, use the `gray` palette.
```@example 2dt
using Images, TestImages
img = testimage("lake_gray");
ii = channelview(img)[1,:,:].*255;
@gpkw imagesc({palette = :gray}, ii)
```
An RGB image is a plot of a 3-D array, where  `[1,;,:]`
is the red channel, `[2,:,:]` is the green channel, and
`[3,:,:]` is the blue channels.
```@example 2dt
img = testimage("lake_color")
@gpkw imagesc({size = "square", autoscale = "fix"}, channelview(img).*255)
```

#### Surfaces

| command | settings theme | plotline theme |
|:--------|:---------------|:---------------|
|`wireframe` | `:hidden3d` | none |
|`surf` | `:hidden3d` | `:pm3d` |

A surface can be plotted as a "wireframe" (or a "mesh") with the `wireframe`
command. By default, `hidden3d` is active, so that elements behind the surface
are not plotted.
```@example 2dt
f1(x,y) = sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
th = @gpkw {title = Q"Sombrero Wireframe", palette = :matter}
@gpkw wireframe(th, (-15, 15, 30), f1)
```
Solid surfaces can be plot with `surf`:
```@example 2dt
th = @gpkw {title = Q"Sombrero Surface", palette = :matter}
@gpkw surf(th, (-15, 15, 200), f1)
```
When plotting a function and a single range (such as `(-15, 15, 200)` above) is given, it is used for
both `x` and `y` coordinates. Two ranges may be given as well to control the `x` and `y` ranges
separately:
```@example 2dt
@gpkw surf(th, (-15, 15, 200), (-25, 5, 200), f1)
```

#### Contour plots

| command | settings theme | plotline theme |
|:--------|:---------------|:---------------|
|`contour` | `:contour` | `:labels` |
| `surfcountour` | `:contourproj` | `:labels` |

By default, contour plots include numerical labels:
```@example 2dt
f2(x,y) = cos(x/2)*sin(y/2)
contour("set title 'Contour Plot'", (-10, 10, 50), f2)
```
To plot contours without labels, use the keyword argument `labels = false`:
```@example 2dt
contour("set title 'Contour Plot Without Labels'", (-10, 10, 50), f2, labels = false)
```
It's possible to plot a wireframe surface and a contour projected on the base of the plot
using `surfcountour`:
```@example 2dt
surfcontour("set title 'Surface With Projected Contours'", (-5, 5, 40), f2, "lc 'orange'")
```
The same plot without contour labels:
```@example 2dt
surfcontour("set title 'Surface With Contours, No Labels'", (-5, 5, 40), f2, "lc 'orange'", labels = false)
```

#### Heatmap plots

| command | settings theme | plotline theme |
|:--------|:---------------|:---------------|
|`heatmap` | `:heatmap` | `:pm3d` |

```@example 2dt
theme = @gpkw {palette = :matter, title = Q"Heatmap"}
heatmap(theme, :notics, :nocb, :labels, (-10, 10, 70), f2)
```

##### Contour lines on heatmap

It is possible to include contour lines in a heatmap plot. The following example is
taken from [this gnuplot blog post]
(https://gnuplot-tricks.blogspot.com/2009/07/maps-contour-plots-with-labels.html).
The function `Gaston.plotwithtable` returns a `Gaston.DataTable`, which wraps
`IOBuffer`. It can be used as an argument to `plot`.
```@example 2dt
# define function to plot
x = y = range(-5, 5, 100)
f4(x,y) = sin(1.3*x)*cos(0.9*y)+cos(.8*x)*sin(1.9*y)+cos(y*.2*x)

# obtain function contours using 'plot with table'
settings = """set contour base
              set cntrparam level incremental -3, 0.5, 3
              unset surface"""
contours = Gaston.plotwithtable(settings, x, y, f4)

# calculate meshgrid for heatmap plot
z = Gaston.meshgrid(x, y, f4)

# plot heatmap and contours
plot("""unset key
        unset colorbox
        set palette rgbformulae 33,13,10""",
        x, y, z, "with image")
plot!(contours, "w l lw 1.5 lc 'slategray'")
```

## Other examples

#### [3-D Euler spiral (Clothoid)](https://en.wikipedia.org/wiki/Euler_spiral)

```@example 2dt
using QuadGK
z = range(-5, 5, 200)
fx(z) = sin(z^2)
fy(z) = cos(z^2)
x = [quadgk(fx, 0, t)[1] for t in z]
y = [quadgk(fy, 0, t)[1] for t in z]
splot("""unset zeroaxis
         set tics border
         set xyplane at -5 
         set view 65,35
         set border 4095""",
         x, y, z, "w l lc 'black' lw 1.5")
```

#### Waterfall

Inspired by this [Julia Discourse discussion](https://discourse.julialang.org/t/how-to-produce-a-waterfall-plot-in-julia/93441).
```@example 2dt
x = -15:0.1:15
y = 0:30
u1data = [exp(-(x-0.5*(y-15))^2) for x in x, y in y]
Zf = fill(0.0, length(x))
f = Figure()
Gaston.set!(f(1), """set zrange [0:2]
               set tics out
               set ytics border
               set xyplane at 0
               set view 45,5
               set zrange [0:3]
               set xlabel 'ξ' offset -0,-2
               set ylabel 't'
               set zlabel '|u|'
               set border 21""")
for i in reverse(eachindex(y))
    Y = fill(y[i], length(x))
    Z = u1data[:,i]
    splot!(x, Y, Z, Zf, Z, "w zerrorfill lc 'black' fillstyle solid 1.0 fc 'white'")
end
f
```

## Plot recipes

There are two ways to extend Gaston to plot arbitrary types. The first is to define a new
function that takes the required type, and returns a `Gaston.Figure`. For example, we may wish to plot
complex data as two subplots, with the magnitude and phase of the data. This can be done as follows:
```@example 2dt
function myplot(data::Vector{<:Complex}; kwargs...)
                    x = 1:length(data)
                    y1 = abs2.(data)
                    y2 = angle.(data)
                    Gaston.sthemes[:myplot1] = @gpkw {grid, ylabel = Q"Magnitude"}
                    Gaston.sthemes[:myplot2] = @gpkw {grid, ylabel = Q"Angle"}
                    Gaston.pthemes[:myplot1] = @gpkw {w = "lp"}
                    Gaston.pthemes[:myplot2] = @gpkw {w = "p", lc = "'black'"}
                    f = Figure(multiplot = "layout 2,1")
                    plot(f[1], x, y1, stheme = :myplot1, ptheme = :myplot1)
                    plot(f[2], x, y2, stheme = :myplot2, ptheme = :myplot2)
                    return f
                end
t = range(0, 1, 20)
myplot(exp.(t) .* cis.(2*pi*7.3*t))
```
The use of themes allows the user to modify the default properties of the plot, by modifying the
themes (such as `Gaston.sthemes[:myplot1]`) instead of having to re-define `myplot`.

The second way to plot an arbitrary type is to define a new method of `Gaston.convert_args` for that
type (or `Gaston.convert_args3` for 3-D plots). Here's an example:

```@example 2dt
using Gaston: PlotObject, TimeSeries, TSBundle
import Gaston: convert_args

struct MyType end

function convert_args(x::MyType)
    t1 = range(0, 1, 40)
    t2 = range(-5, 5, 50)
    z = Gaston.meshgrid(t2, t2, (x,y) -> cos(x)*cos(y))
    @gpkw PlotObject(
        TSBundle(
            TimeSeries(1:10, rand(10)),
            settings = {title = Q"First Axis"}
        ),
        TSBundle(
            TimeSeries(t1, sin.(5t1), pl = {lc = Q"black"}),
            TimeSeries(t1, cos.(5t1), pl = {w = "p", pt = 16}),
            settings = {title = Q"Trig"}
        ),
        TSBundle(
            TimeSeries(t2, t2, z, pl = {w = "pm3d"}, is3d = true),
            settings = {title = Q"3D",
                        tics = false,
                        palette = (:matter, :reverse)}
        ),
        TSBundle(
            TimeSeries(1:10, 1:10, rand(10,10), pl = "w image"),
            settings = {tics, title = false}
        ),
        mp_settings = "title 'A Four-Axes Recipe' layout 2,2"
    )
end

figure().multiplot = "" # hide
plot(MyType())
```
