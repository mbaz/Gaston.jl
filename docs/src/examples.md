# Examples

The plots below have been rendered in a `png` terminal with the following configuration:
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
as a list of keyword arguments. These arguments can be stored in a "theme" using the
`@gpkw` macro:
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
plotline = @gpkw {with = "lp", lc = Q"sea-green", pt = :fcircle, ps = 1.5}
@plot settings x y plotline
```
would produce the same plot. Settings and plotline parameters can also be specified as strings;
see the [Manual](@ref) for all the details. Gaston also has a number of built-in [Themes](@ref).

A `plot` command can only generate a single curve. Use `plot!` or `@plot!` to append a curve:
```@example 2dt
plotline = @gpkw {with = "lp", lc = Q"sea-green", pt = :fcircle, ps = 1.5} # hide
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
g(x) = exp(-abs(x/5))*cos(x)  # function to plot
tt = "set title 'g = x -> exp(-abs(x/5))*cos(x))'"
plot(tt, (-10, 10, 200), g) # plot from x = -10 to 10, using 200 samples
```
Ranges can be specified in the following alternative ways:
```julia
plot(g)            # 100 samples, from -10 to 9.99
plot((a, b), g)    # 100 samples, from a to b
plot((a, b, c), g) # c samples, from a to b
plot(x, g)         # g.(x)
```

#### Multiplots

A convenient, automatic method to create multiplot figures is provided. First, use the helper
function `MultiFigure`, providing the arguments to `set multiplot`:

```julia
f = MultiFigure("title 'Auto Layout'")
```
Then, add plots by indexing into the figure:
```@example 2dt
f = MultiFigure("title 'Auto Layout'") # hide
plot(f[1], x, y)
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

To get full control of the layout, pass the argument `autolayout = false` to `MultiFigure`:
```@example 2dt
f = MultiFigure("title 'Arbitrary multiplot layout demo'", autolayout = false)
x = randn(100)
y = randn(100)
@plot(f[1], {margins = (0.1, 0.65, 0.1, 0.65)},
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

## 3-D Plots
Plotting in 3-D is similar to 2-D, except that `splot` (and `@splot`, `splot!`, `@splot!`) are used
instead of `plot`. This example shows how to plot the surface defined by function `s`:
```@example 2dt
closefigure(f)  # hide
x = y = -15:0.2:15
s = (x,y) -> @. sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
@splot "set title 'Sombrero'" "set hidden3d" {palette = :cool} x y s "w pm3d"
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

The following examples illustrate how to create and display animations, in this case with a
background image:
```@example 2dt
frames = 75 # number of animation frames
# new, empty figure
f = Figure()
# create a background curve that is shown in all frames
x_bckgnd = range(-1, 1, 200)  # x values for the background image
bckgnd = Gaston.Plot(x_bckgnd, sin.(2π*2*x_bckgnd), "lc 'black'")  # background curve
# generate all frames
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

A difficulty arises when mixing plot formats in a notbook (say, `png` and
`gif`): the terminal is specified in the configuration variable `Gaston.config.term`.
However, some notebook programs (such as Pluto) execute cells in arbitrary
order. This means that changing the terminal in one cell may affect other
cells.

To solve this problem, Gaston provides a way to ignore the global terminal
configuration when rendering a plot. A figure `f` can be rendered with a given
terminal by calling `animate(f, term)`. The default value of `term` is stored
in `Gaston.config.altterm` and defaults to `gif animate loop 0`. Examples are
provided in these [interactive Pluto
notebooks](https://github.com/mbaz/Gaston.jl/tree/master/notebooks).

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
the first data row is plotted horizontally and at the top.
```@example 2dt
X = [0 1 2 3;
     0 3 2 1;
     0 2 2 0;
     3 0 0 0]
imagesc("unset xtics", "unset ytics", X)
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
Solid surfaces are plotted with `surf`:
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
surfcontour("set title 'Surface With Contours, No Labels'",
            (-5, 5, 40), f2, "lc 'orange'", labels = false)
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
         set border 4095
         set xtics offset 0, -0.5""",
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
Gaston.set!(f(1), """set zrange [0:1.5]
               set tics out
               set ytics border
               set xyplane at 0
               set view 45,17
               set xlabel 'ξ'
               set ylabel 't' offset -2.5
               set zlabel '|u|' offset -0.85
               set border 21
               set size 1, 1.3""")
for i in reverse(eachindex(y))
    Y = fill(y[i], length(x))
    Z = u1data[:,i]
    splot!(x, Y, Z, Zf, Z, "w zerrorfill lc 'black' fillstyle solid 1.0 fc 'white'")
end
f
```

#### Line color from palette

```@example 2dt
x = -2π:0.05:2π
@plot {palette = :ice} x sin.(3x) x "w l notitle lw 3 lc palette"
```

#### Variable marker size and color

```@example 2dt
x = 0:0.1:6π
splot("unset colorbox",
      x, cos.(x), sin.(x), x./10,
      "w p", "ps variable", "pt 7", "lc palette")
```

#### Filled curve in 3D

```@example 2dt
x = 0.:0.05:3;
y = 0.:0.05:3;
z = @. sin(x) * exp(-(x+y))
@gpkw splot(:labels, {style = "fill transparent solid 0.3", xyplane = "at 0", grid, lt = :Set1_5},
            x, y, z, z.*0, z,
            "w zerror t 'Data'")
splot!(x.*0, y, z, "w l lw 3")
splot!(x, y.*0, z, "w l lw 3")
```

Here, `Set1_5` is a color scheme from [ColorSchemes.jl](https://github.com/JuliaGraphics/ColorSchemes.jl).

#### Spheres

##### Wireframe

```@example 2dt
Θ = range(0, 2π, length = 100)
Φ = range(0, π, length = 20)
r = 0.8
x = [r*cos(θ)*sin(ϕ) for θ in Θ, ϕ in Φ]
y = [r*sin(θ)*sin(ϕ) for θ in Θ, ϕ in Φ]
z = [r*cos(ϕ)        for θ in Θ, ϕ in Φ]
@gpkw splot({view = "equal xyz", pm3d = "depthorder", hidden3d},
            x, y, z,
            {w = "l", lc = Q"turquoise"})
```

##### Surface

```@example 2dt
Θ = range(0, 2π, length = 100)
Φ = range(0, π, length = 100)
r = 0.8
x = [r*cos(θ)*sin(ϕ) for θ in Θ, ϕ in Φ]
y = [r*sin(θ)*sin(ϕ) for θ in Θ, ϕ in Φ]
z = [r*cos(ϕ)        for θ in Θ, ϕ in Φ]
@splot({style = "fill transparent solid 1",
        palette = :summer,
        view = "equal xyz",
        pm3d = "depthorder"},
       x, y, z,
       "w pm3d")
```

#### Torus

See more torus examples in the included Pluto notebook.

```@example 2dt
U  = range(-π,π, length = 50)
V = range(-π,π, length = 100)
r = 0.5
x = [1+cos(u)+r*cos(u)*cos(v) for u in U, v in V]
y = [r*sin(v)                 for u in U, v in V]
z = [sin(u)+r*sin(u)*cos(v)   for u in U, v in V]
settings = """set object rectangle from screen 0,0 to screen 1,1 behind fillcolor 'black' fillstyle solid noborder
              set pm3d depthorder
              set style fill transparent solid 0.5
              set pm3d lighting primary 0.05 specular 0.2
              set view 108,2
              unset border
              set xyplane 0
              unset tics
              unset colorbox"""
@splot(settings, {palette = :cool}, x, y, z, "w pm3d")
```

#### 3D Tubes

##### Wireframe

```@example 2dt
U = range(0, 10π, length = 80)
V = range(0, 2π, length = 10)
x = [(1-0.1*cos(v))*cos(u)     for u in U, v in V]
y = [(1-0.1*cos(v))*sin(u)     for u in U, v in V]
z = [0.2*(sin(v) + u/1.7 - 10) for u in U, v in V]
settings = @gpkw {pm3d = "depthorder",
                  style = "fill transparent solid 1",
                  view = "equal xyz",
                  xyplane = -0.05,
                  palette = :ice,
                  xrange = (-1.2, 1.2),
                  yrange = (-1.2, 1.2),
                  colorbox = false,
                  hidden3d,
                  view = (70, 79)}
@splot(settings, x, y, z, "w l lc 'turquoise'")
```

##### Surface

```@example 2dt
@splot(settings, x, y, z, "w pm3d")
```

#### Dates

```@example 2dt
using Dates

dates = Date(2018, 1, 1):Day(1):Date(2019, 12, 31)
ta = rand(length(dates))
timefmt = "%Y-%m-%d" ## hour:minute:seconds are also available
pfmt = "%Y-%m-%d"
rot_xtics = -35
vals = 0.5*ta
tempo = string.(dates)
xmin1 = "2018-02-01"
xmax1 = "2019-04-01"

@gpkw settings = {xdata = "time",
                  timefmt = "'$(timefmt)'",
                  grid,
                  format = "x '$(pfmt)'",
                  xtics = "rotate by $(rot_xtics)",
                  tmargin = "at screen 0.96",
                  bmargin = "at screen 0.15",
                  lmargin = "at screen 0.1",
                  rmargin = "at screen 0.96",
                  xrange = "['$(xmin1)':'$(xmax1)']",
                  yrange = (-0.25, 0.75)}
plot(settings, tempo, vals, "u 1:2 w l t 'series'")
```

[Source](https://lazarusa.github.io/gnuplot-examples/examples/2d/lines/dates) for this example.

#### Strings

```@example 2dt
x = 10*rand(10)
y = 10*rand(10)
w = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
plot(x, y, w, "w labels")
```

## Defining new plot types and recipes

The following examples illustrate how to extend Gaston to create new types of plots and
to seamlessly plot arbitrary data types.

### Functions that return a `Gaston.Figure`

This example shows how to create a new type of plot: plotting complex data as
two subplots, with the magnitude and phase of the data. The example also
defines new themes.

```@example 2dt
# define new type
struct ComplexData{T <: Complex}
    samples :: Vector{T}
end

# define new themes
Gaston.sthemes[:myplot1] = @gpkw {grid, ylabel = Q"Magnitude"}
Gaston.sthemes[:myplot2] = @gpkw {grid, ylabel = Q"Angle"}
Gaston.pthemes[:myplot1] = @gpkw {w = "lp"}
Gaston.pthemes[:myplot2] = @gpkw {w = "p", lc = "'black'"}

# define new function
function myplot(data::ComplexData; kwargs...)::Figure
                # convert data to a format gnuplot understands
                x = 1:length(data.samples)
                y1 = abs2.(data.samples)
                y2 = angle.(data.samples)
                # create a new multifigure with fixed layout (two rows, one col)
                f = MultiFigure("layout 2,1", autolayout = false)
                # add two plots to f
                plot(f[1], x, y1, stheme = :myplot1, ptheme = :myplot1)
                plot(f[2], x, y2, stheme = :myplot2, ptheme = :myplot2)
                return f
end

# plot example: complex damped sinusoid
t = range(0, 1, 20)
y = ComplexData(exp.(-t) .* cis.(2*pi*7.3*t))
myplot(y)  # plot
```

The use of themes allows the user to modify the default properties of
the plot, by modifying the themes (such as `Gaston.sthemes[:myplot1]`) instead
of having to re-define `myplot`. Of course, similar functionality can be
achieved with the use of keyword arguments.

### Recipes: Adding new methods to `Gaston.convert_args`

The following example shows how to extend `Gaston.convert_args` to plot a
custom type `Data1`. This simple example returns a `Gaston.Plot` object
(essentially a curve), which contains data and a plotline.


```@example 2dt
using Gaston: Plot
import Gaston: convert_args

# define custom type
struct Data1
    samples
end

# add method to convert_args
function convert_args(d::Data1, args... ; pl = "", kwargs...)
    x = 1:length(data.samples)
    y = data.samples
    Plot(x, y, pl)
end

# create some data
data = Data1(rand(20))

# plot
plot("set title 'Simple data conversion recipe'", data, "w lp pt 7 lc 'olive'")
```

Note that this kind of recipe will also seamlessly work with `plot!`, which
adds the curve to the current axis.

A recipe may also return an entire `Axis` object, with its own settings and
curves. The following example returns an axis with two curves.

```@example 2dt
using Gaston: Plot, Axis

struct Data2 end

function convert_args(x::Data2, args... ; kwargs...)
    x = range(0, 1, 100)
    p1 = Plot(x, cos.(4x), "dt '-' lc 'red' t 'cosine'")
    p2 = Plot(x, sin.(5x), "dt '.' lc 'blue' t 'sine'")
    Axis("set grid\nset title 'Full axis recipe'", [p1, p2])
end

plot(Data2())
```

Note that the axis returned by a recipe can be inserted directly into a multiplot:

```@example 2dt
f = MultiFigure("title 'Recipe example'")
plot(f[1], randn(100), "w p")
plot(f[2], Data2())
```

Finally, a recipe can also generate a full multiplot, with multiple axes, as
illustrated in the example below:

```@example 2dt
using Gaston: Plot, Axis, Axis3
import Gaston: convert_args
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
