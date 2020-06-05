# [2-D plotting tutorial](@id twodeetut)

This section provides a brief tutorial on 2-D plotting, with examples on how to obtain common plot types. For full details, we refer the reader to gnuplot's documentation.

## Basics of plotting

A call to `plot` looks like this:

    plot(x, y, z, supp, curvekwargs..., Axes(axeskwargs...))

`x`, `y`, `z` and `supp` are the data to plot. Only `y` is mandatory for 2-D plots. For most plots, vectors are plotted, but plotting images requires a matrix or 3-D array. `supp` is a keyword argument used for supplementary data, which are additional columns that gnuplot can use, such as the errorbar length, or the marker size. Gaston translates the provided data to the format that gnuplot requires, and writes it to a temporary file.

`curvekwargs` is a set of keyword arguments that are related to the appearance of the plotted data. These typically specify the plot style, the line color, the marker type, etcetera. These arguments are used to build a `plot` command for gnuplot. Note that, instead of using a bunch of individual keyword arguments, you can pass gnuplot a complete plot command using the keyword `curveconf`.

`axeskwargs` is a set of keyword arguments wrapped in `Axes()`, which specify the look of the axes, or figure; this refers to things like the plot title, tics, ranges, grid, etcetera. Essentially, anything that can be `set` in gnuplot, can be configured from Gaston by wrapping it in `Axes()`. The special keyword `axesconf` is used to provide a string with commands that are passed literally to gnuplot.

To add a new curve to an existing figure, use `plot!`. It accepts the same arguments as `plot`, except for `Axes()` arguments, which can only be set from `plot`.

The `plot` command has enough flexibility to plot everything that Gaston is capable of. However, Gaston provides a few specialized commands that make certain plots easier. These are illustrated below.

| Command     | Purpose                          |
|-------------|:---------------------------------|
| `scatter`, `scatter!`   | Plot point clouds    |
| `stem`      | Plot discrete (sampled) signals  |
| `bar`       | Plot bar charts                  |
| `histogram` | Plot histograms                  |
| `imagesc`   | Plot images                      |

(Some of the examples below are taken from lazarusa's [excellent gallery](https://lazarusa.github.io/gnuplot-examples/gallery/)).

## Debug mode

If you want to see exactly what commands Gaston is sending to gnuplot, you can turn on debug mode:

    set(debug = true)

Use `set(debug = false)` to turn this mode off.

## Set the plot style, line color, line pattern, line width, and markers

The plot style is set with the keys `w`, `with`, or `plotstyle`. Gnuplot supports many different plot styles; for example, `lines` means plotting a line, `points` is just the markers, and `linespoints` is a line with markers. See all the details in gnuplot's documentation.

The line color is set with `lc` or `linecolor`; while the line width is specified with `linewidth` or `lw`. The marker type is configured with `pointtype`, `pt` or `marker`. Usually gnuplot identifies each marker type by a number, but Gaston provides some equivalent names (see [Introduction to plotting](@ref). The marker size is configured with `pointsize`, `ps` or `ms`. The number of markers may be configured with `pointnumber` or `pn`.

The line style can be configured in multiple ways; one is to specify `linestyle` or `ls` followed by a pattern of dashes and points such as `'-.-'`.

The plotted curve can be given a legend with `title` or `legend`.

The following examples use all these options.

```@example 2dtut
using Gaston # hide
set(reset=true) # hide
set(termopts="size 550,325 font 'Consolas,11'") # hide
# plot with lines and markers
t = -5:0.05:5
plot(t, sin,
            # linespoints plot style
            w  = :lp,
            # line color
            lc = :turquoise,
            # line width
            lw = 3,
            # empty circles
            marker = "ecircle",
            # marker size
            ms = 1.5,
            # plot only ten markers
            pn = 10,
            # legend
            legend = :A_sine_wave
           )
```

```@example 2dtut
# plot with dashed line
plot(t, sin,
            # lines plot style
            w  = :l,
            # line width
            lw = 3,
            # dashed line
            ls = "'-.-'"
           )
```

## Set the plot title, axis labels, tics, legends and grid

Since these are attributes of the entire figure, they must be wrapped by `Axes()`. The title is set with `title`, the axis labels with `xlabel` and `ylabel`.

The tics are configured with `xtics` and `ytics`. The grid can be turned on with `grid`. The position and shape of the legend box is configured with `key`.

The following example shows how to use these attributes.

```@example 2dtut
plot(t, sin,
            w  = :lp, lc = :turquoise, lw = 3,
            marker = "ecircle", ms = 1.5,
            pn = 10, legend = :A_sine_wave,
            Axes(# set the title
                 title = "'Example plot'",
                 # turn on the grid
                 grid = :on,
                 # specify tics
                 xtics = -5:2:5,
                 ytics = ([-1 0 1], ["- one", "zero", "+ one"]),
                 # configure legend box
                 key = "outside center bottom"
                 ))
```

## Logarithmic plots

The axes can be configured to have a logarithmic scale, using `axis = semilogy`, `semilogx`, or `loglog`.

```@example 2dtut
using SpecialFunctions
Q(x) = 0.5erfc(x/sqrt(2))
SNR = 1:15
plot(10log10.(SNR), Q.(sqrt.(SNR)),
     Axes(axis = "semilogy",
          xlabel = "'Signal to Noise Ratio (dB)'",
          ylabel = "'Bit Error Rate'",
          ytics  = "out format '10^{%T}'",
          grid   = "xtics mytics",
          title  = "'BPSK Bit Error Rate'"))
```

## Step plots

In step plots, data points are joined with a horizontal line. To obtain a step plot, set the plot style to `steps`, `fsteps`, or `fillsteps`.

```@example 2dtut
t = -2:0.06:2
plot(t, sin.(2π*t),
     plotstyle = :steps,
     Axes(title = "'Steps plot'"))
```

```@example 2dtut
plot(t, sin.(2π*t),
     w = :fillsteps,
     Axes(style = "fill solid 0.5",
          title = "'Fillsteps plot'"))
```

The color can be specified with `fillcolor`:

```@example 2dtut
plot(t, sin.(2π*t),
     w = :fillsteps,
     fc = :plum,
     Axes(style = "fill solid 0.5",
          title = "'Fillsteps plot'"))
```

## Plotting with financial and error bars

Gaston supports plotting using financial and error bars, by setting the plot style appropriately. Supplementary data is passed to gnuplot using the argument `supp`.

```@example 2dtut
x = 1:0.5:8
open = 3*(0.5 .- rand(length(x)))
close = open .+ 1;
low = open .- 1;
high = open .+ 1.5;
fin = [low high close]
plot(x, open, supp = fin, plotstyle = "financebars",
     Axes(title = "'Example of financial bars'"))
```

```@example 2dtut
x = 0:2:50
y = @. 2.5x/(5.67+x)^2
err = 0.05*rand(length(x))
plot(x, y, supp = err, plotstyle = :errorlines,
     Axes(title = "'Example of error lines'"))
```

## Plotting filled curves

To "fill" the area below a curve, use the plot style "filledcurves". In the example below, we use `curveconf` to pass a full plot command to gnuplot. The `style` is set to `transparent`, so one plot will not obscure those behind it.

```@example 2dtut
x = LinRange(-10,10,200)
fg(x,μ,σ) = exp.(.-(x.-μ).^2 ./(2σ^2))./(σ*√(2π))
plot(x, fg(x, 0.25, 1.5),
     curveconf = "w filledcu lc '#E69F00' dt 1 t '0.25,1.5'",
     Axes(style = "fill transparent solid 0.3 noborder",
          key = "title 'μ,σ' box 3",
          xlabel = "'x'", ylabel="'P(x)'",
          title = "'Example of filled curves'"))
plot!(x, fg(x, 2, 1), curveconf = "w filledcu lc '#56B4E9' dt 1 t '2,1'")
plot!(x, fg(x, -1, 2), curveconf ="w filledcu lc '#009E73' dt 1 t '-1,2'")
```

## Filling the space between two curves

It is possible to fill the space between two curves by providing the second curve as a supplementary column. In this example, gnuplot will fill the space between `sin.(x)` and `sin.(x) .+ 1`.

```@example 2dtut
x = LinRange(-10,10,200)
plot(x, sin.(x) .- 0.2, supp = sin.(x) .+ 0.2,
     curveconf = "w filledcu lc '#56B4E9' fs transparent solid 0.3",
     Axes(title = :Filling_the_space_between_two_curves))
plot!(x, sin.(x), lc = :blue)
```

## Box plots

This example shows the use of supplementary data with the "boxerrorbars" style. the vector `yerr` controls the length of the error bar for each box, while `lcval` assigns each box a color (since `lc palette` is given in `curveconf`). Finally, a color palette is specified using a symbol (`:summer`), which refers to a color scheme from ColorSchemes.jl.

```@example 2dtut
using Random
x = 1:2:20
y = 5*rand(10)
yerr = 0.4*abs.(randn(10))
lcval = 1:10
plot(x, y, supp=[yerr lcval],
     curveconf = "w boxerrorbars notit lc palette fs solid 0.5",
     Axes(palette = :summer,
          xrange=(0,22),
          yrange=(0,6)))
```

## Scatter plots (point clouds)

A scatter plot can be generated with the `scatter` command:

```@example 2dtut
c = 2rand(1000).-1 .+ im*(2rand(1000).-1)
p = filter(x->abs(x)<1, c)
scatter(p,
        marker = "fsquare",
        pointsize = 0.25,
        Axes(object = "ellipse at 0,0 size 2,2",
             title = "'Random points within the unit circle'"))
```

Note that, when the data to plot is complex, the real part is interpreted as the `x` coordinate and the imaginary part as the `y` coordinate.

Besides the standard markers, any UTF-8 character may be used:

```@example 2dtut
scatter(randn(30), randn(30), marker = "λ")
```

### Bubble plots

This example shows how to generate a scatter plot where the color and size of each point is specified with supplementary data. This example also shows how to turn off the colorbox.

```@example 2dtut
n = 40
x, y, z = randn(n), randn(n), randn(n)
plot(x, y, supp = [5z z],
     curveconf = "w p notit pt 7 ps var lc palette",
     Axes(palette = :ice,
          xrange = (-2.2, 2.5),
          yrange = (-2.2, 2.2),
          colorbox = :off))
```

!!! info "`scatter` with gnuplot"
    Behind the scenes, `scatter` calls `plot` with the `points` plotstyle.

## Stem plots

Stem plots make it obvious one is plotting a discrete-time signal. The `stem` command replicates the behavior of `stem` in Matlab, Octave, et al:

```@example 2dtut
t = -2:0.06:2
stem(t, sin.(2π*t))
```

By default, the line color is blue and the lines are made sligthly thicker. If only the vertical lines ("impulses") are desired, pass the option `onlyimpulses=true` to `stem`:

```@example 2dtut
stem(t, sin.(2π*t), onlyimpulses = true)
```

!!! info "`stem` with gnuplot"
    Behind the scenes, `stem` calls `plot` with the `impulses` plotstyle, followed (if `onlyimpulses == true`) by a call to `plot!` with the `points` plotstyle and the pointtype set to `"ecircle"`.

## Bar plots

Bar plots can be generated with the `bar` command:

```@example 2dtut
year = range(1985, length=20);
data = 0.5 .- rand(20)
bar(year, data,
    fc = "'dark-goldenrod'",
    legend = "'Random number'",
    Axes(xtics = "rotate",
        key = "box under",
        boxwidth = 0.66,
        style = "fill pattern 2")
   )
```

!!! info "`bar` with gnuplot"
   Behind the scenes, `bar` uses gnuplot's `boxes` plotstyle, with a default box width of 0.8 and solid fill.

## Histograms

To plot histograms, use the `histogram` command. This command takes the same properties as `bar`. In addition, `histogram` accepts a `bins` parameter, used to specify the number of bins, and a `norm` parameter that can be used to normalize the area under the histogram.

```@example 2dtut
histogram(rand(10000),
          bins = 15,
          norm = 1,
          Axes(title = :Histogram,
               yrange = "[0:1.8]"))
```

It is of course possible to use `histogram` (or any other plot command) along with `plot!` to produce different kinds of plots in the same figure:

```@example 2dtut
x = -5:0.05:5
data = randn(10000)
gaussian = @. exp(-x^2/2)/sqrt(2π)
histogram(data,
          bins = 25,
          norm = 1,
          legend = "'Experimental'",
          linecolor = :turquoise,
          Axes(boxwidth = "0.8 relative",
               title = "'Experimental and Theoretical Gaussian distributions'",
               key = "box top left"))
plot!(x, gaussian,
      linecolor = :black,
      legend = "'Theoretical'")
```

## Images

The command to plot an image is `imagesc`. It can plot a scaled or RGB image, depending on whether the provided coordinates are an array with two or with three dimensions.

Note that `imagesc` interprets the `x` axis as the columns of the matrix. In other words, element `[1,1]` is located in the top-left corner of the plot, and element `[end:1]` is in the bottom-left corner.

### Scaled image

A scaled image is a plot of a matrix whose elements are interpreted as grayscale values (which may be displayed in color with a given palette).

```@example 2dtut
Z = [5 4 3 1 0 ;
     2 2 0 0 1 ;
     0 0 0 1 0 ;
     0 1 2 4 3]
imagesc(Z, Axes(title = "'Simple scaled image'", palette = :summer))
```

To display the image as grayscale, use the `gray` palette.

```@example 2dtut
using Images
using TestImages
img = testimage("lake_gray");
ii = channelview(img)[1,:,:].*255;
imagesc(ii, Axes(palette = :gray))
```

### RGB image

An RGB image is a plot of a 3-D array whose elements are interpreted as the red, green, and blue components of each image pixel. The array's `[1,;,:]` elements are a matrix representing the red channel, while `[2,:,:]` and `[3,:,:]` are the green and blue channels respectively.

```@example 2dtut
img = testimage("lake_color")
imagesc(channelview(img).*255,
        Axes(size = "square", autoscale = "fix"))
```
