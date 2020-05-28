```@meta
Author = "Miguel Bazdresch"
```

# Introduction to plotting

Gaston can create 2-D plots, including regular function plots, plots with logarithmic axes, scatter, stem and step plots, bar plots and histograms, and images.

It can also create 3-D plots, including wireframe, surface, scatter and contour plots. 

## `plot` and `plot!` commands

The main 2-D plotting commands are `plot` and `plot!`. To plot a vector `y` against a vector `x`, use `plot(x,y)`:

```@example t1
using Gaston # hide
set(reset=true) # hide
set(mode="ijulia") # hide
set(size="500,300") # hide
nothing # hide
t = 0:0.01:1
plot(t, sin.(2π*5*t))
```

To add a second curve, use `plot!`:

```@example t1
plot!(t,cos.(2π*5*t))
```

Curves are added to a figure one by one; the first curve is plotted with `plot`, and the rest with succesive `plot!` commands.  In plots with multiple curves, the axes must be configured with the first `plot` command; `plot!` only allows configuration of the respective curve.

## Other 2-D plot commands

There are some commands to create specialized plots. These are:

| Command     | Purpose                          |
|-------------|---------------------------------:|
| `scatter`   | Plot point clouds                |
| `stem`      | Plot discrete (sampled) signals  |
| `bar`       | Plot bar charts                  |
| `histogram` | Plot histograms                  |
| `imagesc`   | Plot images                      |

## 3-D plotting

Gaston can plot 3-D surfaces using the `surf` command; it accepts the same properties as `plot`, but it adds `zlabel` and `semilogz` axis properties, and a `pm3d` plotstyle. In addition, `surf!` allows plotting multiple surfaces in the same figure, and `contour` can display simple contour maps. The command `scatter3` can be used to plot a 3-D point cloud.

These commands require vector `x` and `y` coordinates. The `z` coordinate can be passed explicitly (as a matrix), or as a function. See [3-D Examples](@ref) for examples using these commands.

## Plot configuration

Many plot properties can be configured. These properties are divided in _axes properties_ (grid, axes labels, etc) and _curve properties_ (color, line style, point type, etc). See the full list in [Settings and Configuration](@ref).

Configuration options can be provided as strings, as numbers (where it makes sense), or as symbols, as in `linecolor = :red`.

The axes configuration can be provided as arguments to `plot`:

```@example t1
plot(t, sin.(2π*10*t),
    title="Sine wave",
    grid="on",
    xlabel="Time(s)",
    ylabel="Amplitude (V)")
```

Curve properties can be mixed with axes properties:

```@example t1
plot(t, sin.(2π*3*t),
    linewidth = 2,
    linecolor = :red,
    marker = :ecircle,
    plotstyle = :linespoints,
    linestyle = "-.-",
    xlabel = "Time(s)",
    ylabel = "Amplitude (V)")
```

Many options can be specified with shorter names; for example, the `plot` command above can be replaced with:

```@julia
plot(t, sin.(2π*3*t),
    lw = 2,
    lc = :red,
    mk = :ecircle,
    ps = :linespoints,
    ls = "-.-",
    xlabel = "Time(s)",
    ylabel = "Amplitude (V)")
```
## Legends

Legends can be added with `keyoptions` and `legend`:

```@example t1
t = -5:0.01:5
plot(t, sinc.(t),
     keyoptions = "box top left",
     legend = "Sinc(t)")
```

## Setting the background

The background color can also be configured:

```@example t1
t = -5:0.01:5
plot(t, sinc.(t),
     linecolor = :yellow,
     linewidth = 3,
     background = :blue)
```

## Ranges

Ranges can be specified with `xrange` and `yrange`. The range format follows gnuplot's syntax.

```@example t1
t = -5:0.01:5
plot(t, sinc.(t),
     xrange = "[-5:*]",
     yrange = "[-1:1.5]")
```

## Plotting the ``y=0`` and ``x=0`` axes

A neat gnuplot feature exposed by Gaston is the ability to plot the ``y=0`` and ``x=0`` axes:

```@example t1
t = -5:0.01:5
plot(t, sinc.(t.+1),
     xzeroaxis = :on,
     yza = :on)
```

## Font and font size

The font and font size can be set with `font`:

```@example t1
plot(t, sinc.(t),
     font = "Consolas, 12")
```

## Plot size

The plot size can be controlled with `size`. (Be careful to use the correct units for your chosen terminal -- in particular, pdf terminals specify the size in inches).

```@example t1
plot(t, sinc.(t),
     size = "200,200")
```

## Advanced configuration with `gpcom`

Although Gaston does not expose all of gnuplot's capabilities, arbitrary gnuplot commands can be specified using the `gpcom` argument to `plot`. This string is passed to gnuplot right before the `plot` command is issued. An example is a custom tics specification:

```@example t1
t = -5:0.01:5
plot(t, sinc.(t),
     gpcom = "set xtics -5,2,5; set ytics 0,0.5,1")
```

## Setting default values

Default values can be configured with the `set` command. For example,

```julia
set(linewidth=5)
```

will cause all subsequent curves to be plotted using a line width of 5. However, properties specified in `plot` arguments override the default properties.

To elaborate: settings are taken from gnuplot's initialization file first, then from user-configured default values, then from those specified in `plot`.
