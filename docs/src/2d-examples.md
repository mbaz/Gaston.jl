# 2-D Examples

This section shows examples of many types of 2-D plots, including the use of specialized commands such as `stem` and `scatter`.

## Logarithmic plots

The axes can be configured to have a logarithmic scale, using `axis=semilogy`, `semilogx`, or `loglog`.

```@example t1
using Gaston # hide
set(reset=true) # hide
set(mode="ijulia") # hide
set(size="500,300") # hide
nothing # hide
t = 0:0.01:1
plot(t, sin.(2π*10*t),
     axis = "semilogx",
     xlabel = "log(time)",
     ylabel = "Amplitude",
     grid = "on")
```

## Scatter plots

A scatter plot can be generated with the `scatter` command:

```@example t1
c = 2rand(1000).-1 .+ im*(2rand(1000).-1)
p = filter(x->abs(x)<1, c)
scatter(p,
        marker = :fsquare,
        pointsize = 0.25,
        gpcom = "set object ellipse at 0,0 size 2,2",
        title = "Random points within the unit circle")
```

Note that, when the data to plot is complex, the real part is interpreted as the `x` coordinate and the imaginary part as the `y` coordinate.

Besides the standard markers, any UTF-8 character may be used:

```@example t1
scatter(randn(30), randn(30), marker = "λ")
```

Behind the scenes, `scatter` calls `plot` with the `points` plotstyle.

## Stem plots

Stem plots make it obvious one is plotting a discrete-time signal. The `stem` command replicates the behavior of `stem` in Matlab, Octave, et al:

```@example t1
t = -2:0.06:2
stem(t, sin.(2π*t),
     markersize = 0.75)
```

By default, the line color is blue and the lines are made sligthly thicker. If only the vertical lines ("impulses") are desired, pass the option `onlyimpulses=true` to `stem`:

```@example t1
stem(t, sin.(2π*t), onlyimpulses = true)
```

Behind the scenes, `stem` calls `plot` with the `impulses` plotstyle, followed (if `onlyimpulses == true`) by a call to `plot!` with the `points` plotstyle and the pointtype set to `ecircle`.

## Plotting matrices

When the data to plot is a matrix, each column is plotted. An `x` argument can optionally be provided; if missing, the row number is used as index. Plot configuration such as line width, markers and colors are used cyclically.

```@example t1
plot(20:0.1:

## Step plots

In step plots, data points are joined with a horizontal line. There are three variants: `steps`, `fsteps`, and `fillsteps`.

```@example t1
t = -2:0.06:2
plot(t, sin.(2π*t),
     plotstyle = :steps,
     title = "Steps plot")
```

```@example t1
plot(t, sin.(2π*t),
     ps = :fillsteps,
     fillstyle = "solid 0.5",
     title = "Fillsteps plot")
```

The color can be specified with `fillcolor`:

```@example t1
plot(t, sin.(2π*t),
     plotstyle = :fillsteps,
     fillstyle = "solid 0.75",
     fillcolor = "plum",
     title = "Fillsteps plot")
```

## Bar plots

Bar plots can be generated with the `bar` command:

```@example t1
year = range(1985, length=20);
data = 0.5 .- rand(20)
bar(year, data, gpcom = "set xtics rotate")
```

Behind the scenes, `bar` uses gnuplot's `boxes` plotstyle. The bars' width, color and fillstyle can be controlled:

```@example t1
bar(year, data,
    gpcom = "set xtics rotate",
    legend = "Random number",
    keyoptions = "box under",
    boxwidth = 0.66,
    fillstyle = "pattern 2",
    fillcolor = "dark-goldenrod")
```

## Histograms

To plot histograms, use the `histogram` command. This command takes the same properties as `bar`. In addition, `histogram` accepts a `bins` parameter, used to specify the number of bins, and a `norm` parameter that can be used to normalize the area under the histogram.

```@example t1
histogram(rand(10000),
          bins = 15,
          norm = 1,
          title = "Histogram",
          yrange = "[0:1.8]")
```

It is of course possible to use `histogram` (or any other plot command) along with `plot!` to produce different kinds of plots in the same figure:

```@example t1
x = -5:0.05:5
data = randn(10000)
gaussian = @. exp(-x^2/2)/sqrt(2π)
set(keyoptions="box top left")
histogram(data,
          bins = 25,
          norm = 1,
          legend = "Experimental",
          linecolor = :turquoise,
          boxwidth = "0.8 relative",
          title = "Experimental and Theoretical Gaussian distributions")
plot!(x,gaussian,
      linecolor = :black,
      legend = "Theoretical")
```

## Images

The command to plot an image is `imagesc`. It can plot a scaled or RGB image, depending on whether the provided coordinates are an array with two or with three dimensions. This command takes the properties `title`, `xlabel`, `ylabel`, `xrange` and `yrange`. In addition, RGB images can take a parameter `clim`, which must be a two-element array, and which is used to scale the image values.

### Scaled image

A scaled image is a plot of a matrix whose elements are interpreted as colors.

```@example t1
set(keyoptions="") #hide
Z = [5 4 3 1 0; 2 2 0 0 1; 0 0 0 1 0; 0 1 2 4 3]
imagesc(Z, title = "Simple scaled image")
```

### RGB image

An RGB image is a plot of a 3-D matrix whose elements are interpreted as the red, green, and blue components of each image pixel.

```@example t1
R = [x+y for x=0:5:120, y=0:5:120]
G = [x+y for x=0:5:120, y=120:-5:0]
B = [x+y for x=120:-5:0, y=0:5:120]
Z = zeros(25,25,3)
Z[:,:,1] = R
Z[:,:,2] = G
Z[:,:,3] = B
imagesc(Z,
        title = "RGB Image",
        clim = [10,200],
        xrange = "[1:25]",
        yrange = "[1:25]")
```

# rgb image
using Images
using TestImages
img=testimage("lighthouse");
imagesc(channelview(img).*255,size=:square,autoscale=:fix)

# grayscale image
img=testimage("walkbridge");
ii=channelview(img)[1,:,:].*255;
imagesc(ii,palette=:gray)

# glow
x = 0:0.3:4
a = exp.(- x)
b =  exp.(- x.^2)
plot(x,a,w="lp lw 1 lc '#08F7FE' pt 7 t 'e^{-x}'",
                object="rectangle from screen 0,0 to screen 1,1 behind fc 'black' fs solid noborder",
                border="lw 1 lc 'white'",
                xtics="textcolor rgb 'white'",
                ytics="textcolor rgb 'white'",
                ylabel="'y' textcolor 'white'",
                xlabel="'x' textcolor 'white'",
                grid="ls 1 lc '#2A3459' dt 4",
                key="t r textcolor 'white'",
                style="fill transparent solid 0.08 noborder")
plot!(x,b,w="lp lw 1 lc '#FFE64D' pt 7 t 'e^{-x^2}'")
for i in 1:10
       plot!(x,a,w="l lw $(1 + 1.05*i) lc '#F508F7FE' t ''")
       plot!(x,b,w="l lw $(1 + 1.05*i) lc '#F5FFE64D' t ''")
end
plot!(x,a,w="filledcu y=0 lw 1 lc '#08F7FE' t ''")
plot!(x,a,supp=b,w="filledcu lw 1 lc '#FFE64D' t ''")

# filled curves
x = LinRange(-10,10,200)
fg(x,μ,σ) = exp.(.-(x.-μ).^2 ./(2σ^2))./(σ*√(2π))
plot(x,fg(x,0.25,1.5),w="filledcu lc '#E69F00' dt 1 t '0.25,1.5'",
                             style="fill transparent solid 0.3 noborder",
                             key="title 'μ,σ' box 3",
                             xlabel="'x'", ylabel="'P(x)'")
plot!(x,fg(x,2,1),w="filledcu lc '#56B4E9' dt 1 t '2,1'")
plot!(x,fg(x,-1,2),w="filledcu lc '#009E73' dt 1 t '-1,2'")

# fill between
x = LinRange(-10,10,200)
plot(x,sin.(x),supp=sin.(x).+1,w="filledcu lc '#56B4E9' fs transparent solid 0.3")
plot!(x,cos.(x),supp=1.0.+cos.(x),w="filledcu lc 'red' fs transparent solid 0.5")

# boxes
using Random
Random.seed!(145);
x,y=1:2:20,5*rand(10);
yerr=0.4*abs.(randn(10));
lcval=1:10;
plot(x,y,supp=[yerr lcval],w="boxerrorbars notit lc palette fs solid 0.5",palette=:summer, xrange=(0,22), yrange=(0,6))

# bubble plot
using Gnuplot,Random
Random.seed!(124)
n = 30
x, y, z = randn(n), randn(n), randn(n)
plot(x,y,supp=[5z z],w="p notit pt 7 ps var lc palette",palette=:ice,xrange=(-2.2,2.5),yrange=(-2.2,2.2))

# interlocking tori
U = LinRange(-pi, pi, 100) # 50
V = LinRange(-pi, pi, 20)
x = [cos(u) + .5 * cos(u) * cos(v)      for u in U, v in V]
y = [sin(u) + .5 * sin(u) * cos(v)      for u in U, v in V]
z = [.5 * sin(v)                        for u in U, v in V]
surf(x',y',z',w=:pm3d,origin="0.4,0.0",size="0.55, 0.9",palette=:dense,colorbox="vertical user origin 0.005, 0.15 size 0.02, 0.50",pm3d=:depthorder,key=:false,tics=:false,border=0,view="60, 30, 1.5, 0.9",style="fill transparent solid 0.7")
x = [1 + cos(u) + .5 * cos(u) * cos(v)  for u in U, v in V]
y = [.5 * sin(v)                        for u in U, v in V]
z = [sin(u) + .5 * sin(u) * cos(v)      for u in U, v in V]
surf!(x',y',z',w=:pm3d)


## Plotting with financial and error bars

Gaston supports plotting using financial and error bars.

```@example t1
y = [i+rand() for i=1:0.3:8]
open=y.-0.1*rand(length(y));
close=open.+1;
low=open.-1;
high=open.+1.5;
fin = Gaston.FinancialCoords(open,low,high,close)
plot(y, financial=fin,
    title = "Example of financial bars",
    plotstyle = "financebars")
```

```@example t1
x = 0:2:50
y = @. 2.5x/(5.67+x)^2
err = Gaston.ErrorCoords(0.05*rand(length(x)))
plot(x, y,
     err = err,
     title = "Example of error lines",
     plotstyle = :errorlines)
```

## Saving plots

To save a plot (or "print" it, in gnuplot's parlance), use the `printfigure` command:

```julia
printfigure(term = "png",
            font = "Consolas,10",
            size = "1280,900",
            linewidth = 1,
            background = :gray,
            outputfile = "myfigure.png")
```

The `outputfile` argument is required. The `term` argument configures the file type; supported formats are gif, eps, svg, and png. By default the figure is saved in pdf format.
