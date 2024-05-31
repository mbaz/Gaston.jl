### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ ccdce6f8-f1d8-11ed-19e9-fddf2407113b
import Pkg

# ╔═╡ 7076fc20-8f0c-449c-9cfc-edf9801e85cd
# ╠═╡ show_logs = false
Pkg.add("PlutoUI")

# ╔═╡ c55fca39-9251-4593-b7f4-4342119e76e1
# ╠═╡ show_logs = false
Pkg.develop(path="/home/miguel/rcs/jdev/Gaston")

# ╔═╡ a64f470c-a8d3-4c28-99f4-8149ac65ff58
using Revise

# ╔═╡ 93d7c222-6755-4b71-b4cb-3ad82f4515f1
using Gaston

# ╔═╡ dab403c8-f4ae-4029-a8c8-ef5ae161142c
using PlutoUI

# ╔═╡ d4e94a70-866a-46e2-98c2-6babc7745fd2
md"# Gaston demo/tutorial: Essentials

Let's start by loading Gaston and PlutoUI."

# ╔═╡ ff57c40b-615d-4902-9810-8d874220f626
Gaston.GASTON_VERSION

# ╔═╡ a66e7e1d-b3a4-4504-be15-2324808607be
PlutoUI.TableOfContents(title = "Contents")

# ╔═╡ 1a521882-7ee0-413d-9738-3a025499883e
md"## Introduction to Gaston

Gaston is a plotting package for Julia. It provides an interface between Julia and [gnuplot](https://gnuplot.info). Gaston has two main functions:
* Convert Julia data variables to gnuplot's format.
* Provide plot commands with familiar syntax, e.g. `plot(x, y)`.
It also provides some additional functionality:
* Manage multiple figures simultaneously.
* Work seamlessly in notebooks.
* Convenient syntax for configuring gnuplot.
* Recipes (styles) for common plot types.
* Lightweight themes.
* Can be extended to plot user-defined data types.
Familiarity with both Julia and gnuplot is assumed throughout the documentation.
"

# ╔═╡ 8f50fd19-5ce4-447e-a7f9-7b16d59af6c0
md"""## Basic syntax

The `plot` function is Gaston's workhorse for 1-D plotting. It takes three different kinds of arguments, in order: axis settings, data, and curve settings. Axis settings correspond to gnuplot's `set` commands, while curve settings determine how a curve is plotted (its color, width, markers, etc.)

Axis settings and curve settings are strings; any number of them can be used. The signature of `plot` is:

    plot(axis_settings..., data..., curve_settings...)

For example, the command

    plot("set title 'a plot'", "set grid", x, y, "w p lc 'green'")

is converted to the following sequence of gnuplot commands:

    set title 'a plot'
    set grid
    plot '/tmp/data' w p lc 'green'

where `x` and `y` are written to the temporary file `data` in the format gnuplot expects.
"""

# ╔═╡ ab0aba7c-d841-44bb-8e6a-2e5515ef9aa5
md"## Configuring the terminal

When working in a notebook (whether Juno, IJulia, Pluto or VS Code), the terminal is automatically set to `pngcairo`. This terminal is very good for plotting on a notebook, since it's very fast and produces small files. We still want to configure the terminal ourselves, though, to set a good plot size (in pixels) and font size. This is done as follows:"

# ╔═╡ 0e8236b4-6d1f-46ae-9c0e-ee1d4f605c0d
Gaston.config.term = "pngcairo font ',10' size 700,400"

# ╔═╡ fc31bafd-eb7b-4204-b781-6e06cf95fd25
md"## 2-D plots

### Plotting coordinates

Following are some examples of basic plots, with different data arguments.

##### Only `y` is given

The `x` coordinates are implicitly defined as the range `firstindex(y):lastindex(y)`."

# ╔═╡ 804b8b60-8976-43a3-a5b7-86cedf9118e4
plot(rand(10))

# ╔═╡ e467671a-62a2-406d-99e4-9ecfa7f55b5e
md"##### Both `x` and `y` are given"

# ╔═╡ a25f483f-f5c7-4949-9690-3d126a12e86a
plot(range(0, 1, length=10), rand(10))

# ╔═╡ 26fe4805-3b08-4750-b0f8-f210a72a502b
md"##### Multiple columns

Many `gnuplot` plot styles take multiple columns. Each data argument to `plot` is interpreted as a column, and you can use as many as you need:"

# ╔═╡ 21e1f17f-4fb2-490e-ade7-77725fb24f61
let
	x = 1:10
	boxmin = 0.1*rand(10) .+ 0.2
	whiskmin = boxmin .- 0.1*rand(10)
	boxmax = boxmin .+ 0.5*rand(10)
	whiskmax = boxmax .+ 0.2*rand(10)
	ym = minimum(whiskmin)-0.1
	yM = maximum(whiskmax)+0.1
	plot("set yrange [$ym:$yM]
	      set boxwidth 0.3 relative
	      set style fill solid 0.25
	      set title 'A random candlesticks plot'",
	      x, boxmin, whiskmin, whiskmax, boxmax,
	      "w candlesticks whiskerbars 0.75")
end

# ╔═╡ cedb6fa7-e8c7-4a48-8935-1ce6385f1185
md"### Plotting functions

##### Only a function is given

When a function is passed to `plot`, the function is first evaluated in the range from -10 to 10, with 100 samples."

# ╔═╡ 8a50be7a-bcfa-468c-914a-9b1aa2c970ad
fun(x) = exp(-abs(x/8))*cos(x)

# ╔═╡ 6d72504e-fede-41a6-bfef-0aef52936e1b
plot(fun)

# ╔═╡ e15e224f-834c-459e-b355-15d1fb8975fb
md"##### A function and a range

The range can be given explicitly as `(start, stop)`; the function is still sampled 100 times."

# ╔═╡ 162ccb40-92b0-43fe-a89e-676864ac9883
plot((-1, 5), fun)

# ╔═╡ 0b229ed3-868a-42d3-b669-6cacaf213c90
md"The number of samples can be specified with `(start, stop, samples)`."

# ╔═╡ fbce3eb9-6691-4945-ac6b-4b0bcf31e003
plot((-1, 5, 10), fun)

# ╔═╡ 262faf7b-ac62-45d9-bc18-3860e6e10fb7
md"### Plotting multiple curves

To plot multiple curves on the same axis, use `plot!`.

(Note that `plot!` only accetps curve settings; axis settings, must be specified with `plot`)."

# ╔═╡ 57f66b17-8c2d-4737-84e1-c456a7dacc89
begin
	plot("set key box top left", fun, "lc 'dark-green' title 'fun'")
	plot!(cos, "lc 'orange' title 'cos'")
end

# ╔═╡ a0762a24-26be-40a6-a333-92bd8999a5a3
md"### Plot styles

The following commands plot data with a specific plot style:
* `scatter`, `scatter!`
* `stem`, `stem!`
* `bar`, `bar!`
* `barerror`, `barerror!`
* `histogram`
* `imagesc`
The following examples illustrate these styles."

# ╔═╡ d66d3ef3-130f-45a7-81d6-0cac24e9b1d2
md"##### Scatter plot"

# ╔═╡ 4f145f29-f99d-4f36-9ebf-5cc632f956c1
let
	xg = randn(20)
	yg = randn(20)
	scatter("set title 'Scatter plot'
	         set key outside",
		    xg, yg,
		    "title 'gaussian'")
	xu = rand(20)
	yu = rand(20)
	scatter!(xu, yu, "title 'uniform'")
end

# ╔═╡ 970fd5da-91e2-44bb-a427-6823b03c79e9
md"##### Stem plot"

# ╔═╡ 881e794d-bc5e-49d0-b240-2cb58abe82ce
stem("set title 'stem plot'", fun)

# ╔═╡ 996ef179-f5fd-4345-a6af-a74709bd2a6b
md"Avoid printing the circular marks with the `onlyimpulses` argument."

# ╔═╡ f395e87b-39f6-4f79-83b1-1b44bcb37feb
stem("set title 'only impulses'", fun, onlyimpulses = true)

# ╔═╡ 9db5812e-47a3-4b17-b3f0-9e74a38e3f54
md"##### Bar plots

`bar` uses gnuplot's `with boxes` style."

# ╔═╡ 061a881c-220c-4183-8f5b-12fd91a8f358
bar("set title 'bar plot'", rand(10), "lc 'turquoise'")

# ╔═╡ 8c14838e-fcb6-4b49-83cd-a3ef5f267b24
let
	bar("set title 'Two bar plots'",
        rand(10),
		"lc 'dark-violet'")
	bar!(1.5:10.5, 0.5*rand(10), "lc 'plum' fill pattern 4")
end

# ╔═╡ be09ba73-cabb-40ce-aa06-6bfe0705f6e2
md"`barerror` uses gnuplot's `boxerrorbars` style."

# ╔═╡ 33731005-bb8c-48a9-863a-93e25d579930
barerror("set title 'Error bars'",
         1:10, rand(10), 0.1*rand(10).+0.1,
         "lc 'sandybrown'")

# ╔═╡ 906770c9-07bd-4447-af21-de487c7a1e02
md"##### Histograms

The `histogram` function takes these keyword arguments:
* `nbins`: specifies the number of bins. Defaults to 10.
* `norm::Bool`: if `true`, the area of the histogram is normalized.
* `mode::Symbol`: Controls histogram normalization mode; passed to [`StatsBase.normalize`](https://juliastats.org/StatsBase.jl/stable/empirical/#LinearAlgebra.normalize). Defaults to `:pdf`, which makes the histogram area equal to 1.
* `edges`: a vector or a range specifying the bin edges; takes precedence over `nbins`.
* `horizontal::Bool`: if `true`, the histogram is drawn horizontally.
2-D histograms are supported, by passing two datasets.
"

# ╔═╡ 38a71681-dc2d-4af5-be14-1682924abf51
histogram("set title 'histogram (nbins)'",
	      randn(10_000), nbins = 20, norm = true)

# ╔═╡ 5c25b0e3-9a45-4ad5-92ae-314cfce5c117
histogram("set title 'histogram (edges)'",
	      randn(10_000), edges = -5:5,
          "lc 'dark-khaki'")

# ╔═╡ 4f4fb009-cf62-4e64-a519-77f340f83f69
histogram("set title 'horizontal histogram'",
	      rand(1000), nbins = 10, horizontal = true,
          "lc 'orchid'")

# ╔═╡ 84ccf2ff-472b-4b34-9472-2006f70684e6
md"In the case of 2-D histograms, `nbins` or `egdes` may be a tuple; otherwise, both axes use the same configuration."

# ╔═╡ b42213a1-f27a-4c96-a6a7-b5a8a200ef19
let
	x = randn(100_000)
	y = randn(100_000)
	histogram("set palette gray
	           unset colorbox
	           set title '2-D histogram'",
		      x, y, nbins = 50, norm = true)
end

# ╔═╡ e1e93d06-4565-4625-8fcf-fe8dbc9fe55e
md"##### Images"

# ╔═╡ 8ab2a66a-df03-4aeb-a736-1336b75dadaa
md"Arrays may be plotted as images using `imagesc`. Note that, in contrast to other plotting packages, the array columns are plotted vertically."

# ╔═╡ ca7554bc-6f9c-4574-bf78-20afd42dc647
let
	X = [0 1 2 3;
	     0 3 2 1;
	     0 2 2 0;
	     3 0 0 0]
	imagesc("unset tics", X)
end

# ╔═╡ 5acd956b-e22d-4638-be19-1ad090cac7d2
md"""## Plot options

Gnuplot provides many possibilities to fine-tune a plot. There are two main kinds of configuration options:
* Axes-wide options, corresponding to `set` commands; for example, `set grid` turns on the grid.
* Specific curve settings, such as line width and color; for example, `with points linecolor 'red'`.

Gaston provides a few different ways to specify these plot options. In all cases, axes-wide options come before the data to plot, and curve-specific options come afterward.

One way to specify the options is with strings enclosing `gnuplot` commands:
"""

# ╔═╡ 20a9dc74-0324-4d76-88fa-1c55ac281e5e
plot("set title 'A nice sinusoid'
	  set key box left
      unset grid
      set xlabel 'time'
      set ylabel 'voltage'",
	  sin,
      "w points lc 'orange' title 'sin'")

# ╔═╡ a0720ae4-8da5-4ed6-acd9-0471b840fa1d
md"Options may also be given using the following syntax:"

# ╔═╡ dc989e43-20ad-4f03-86a3-655c00c02a4e
@plot({title = "'A nice sinusoid'",
       key = "box left",
       grid = false,
       xlabel = "'time'",
       ylabel = "'voltage'"
	  },
      sin,
      {w = "points",
       lc = "'orange'",
       title = "'sin'"
      })

# ╔═╡ 564caa1c-222f-4655-9505-162f5e23b234
md"""##### Axis-wide options

For axis-wide options (first argument to `@plot` above), `{option = value}` is converted to `"set option value"`. To unset an option, set it to false: `{tics = false}` is converted to `unset tics`.

Curve-specific options (last argument to `@plot` above) are handled similary, but they are used to "build" the plot command given to `gnuplot`.

This syntax offers some convenience features:
* Specify a range as a tuple: `{xrange = (1, 2)}` is converted to `set xrange [1:2]`, while `{yrange = (-Inf, 5)}` is converted to `set yrange [*:5]`.
* To set all ranges (`x`, `y`, `z` and `cb`) simultaneously, use `{ranges = (min, max)}`.
* Specify tics conveniently:
    * `{xtics = 1:2}` is equivalent to `set xtics 1,1,2`
    * `{ztics = 1:2:7})` to `set ztics 1,2,7`
    * `{tics = (0,5)}` to `set tics (0, 5)`
    * `{tics = (labels = ("one", "two"), positions = (0, 5))}` to `set tics ('one' 0, 'two' 5, )`
* Specify a color palette from [Colorschemes.jl](https://juliapackages.com/p/colorschemes). For example, `{palette = :viridis}` is converted to a `set palette` command with the appropriate colors. The palette name must be given as a symbol.
    * To reverse the palette order, specify it as `{palette = (:viridis, :reverse)}`.
* A line type may be specified similary: `{lt = :viridis}`.
* In 3D plots, specify the view as a tuple: `{view = (50, 60)}` is converted to `set view 50, 60`.
* Specify margins, useful for multiplot with arbitrary layouts: `{margins = (0.33, 0.66, 0.2, 0.8)}` is converted to `set lmargin at screen 0.33...`. The margins are specified in the order left, right, bottom, top.

An option may be specified more than one time: `{tics, tics = 1:2}` is converted to

    set tics
    set tics 1,1,2

Any number of option arguments may be given before and after the data to plot, and they will be combined:
"""

# ╔═╡ 52a654cf-9aac-47ba-82d4-6d7b4320d79e
md"Options can also be given as `gnuplot` commands in strings:"

# ╔═╡ 44930880-7dd2-4120-b097-6c19f8e7022a
@plot({title = "'A nice sinusoid'"}, "set key box left", {grid = false},
       "set xlabel 'time'\nset ylabel 'voltage'",
	   sin,
	   {w = "points"}, "lc 'orange' title 'sin'")

# ╔═╡ 5809cde8-fa4d-49a5-bc4f-4baa0133b21f
md"""##### Quoted strings

String arguments given to gnuplot must be quoted. To simplify this, the `qs` string macro might come in handy. The string `qs"a title"` is converted to `"'a title'"`."""

# ╔═╡ 1b7dfb67-6047-40fa-9b91-c48aa8e8aa9c
@plot({title = qs"A nice sinusoid"}, "set key box left", {grid = false},
       {xlabel = qs"time", ylabel = qs"voltage"},
	   sin,
	   {w = "points"}, "lc 'orange' title 'sin'")

# ╔═╡ beb2b6cd-ee6b-4bd8-bf8e-5d071adbd857
md"""##### Curve-specific options

These options affect the way a curve is plotted (line style, color, etcetera), and may be specified as a string (which is passed directly to `gnuplot`) or as a set of options inside `{}` brackets. These options are passed to `gnuplot` as part of the `plot` command. For example, `@plot sin {with = "points", lc = qs"red"}` is converted to a `gnuplot` command `plot <datafile> with points lc 'red'`.

When using the bracketed options format, the following convenient syntax is available:
* `marker` is available as synonym of `pointtype`
* `markersize` and `ms` are available as synonyms of `pointsize`.
* `legend` is available as a synonym of `title`.
* `plotstyle` is a synonym of `with`.
* A point type may be specified by name (instead of just by number as in native `gnuplot`):
| name | gnuplot pt number |
|-----:|:------------------|
| dot | 0 |
| ⋅ | 0 |
| + | 1 |
|  plus     | 1 |
|  x        | 2 |
|  *        | 3 |
|  star     | 3 |
|  esquare  | 4 |
|  fsquare  | 5 |
|  ecircle  | 6 |
|  fcircle  | 7 |
|  etrianup | 8 |
|  ftrianup | 9 |
|  etriandn | 10 |
|  ftriandn | 11 |
|  edmd     | 12 |
|  fdmd     | 13 |
Here a prefix "e" stands for "empty", "f" for "full"; "up" and "dn" stand for "pointing up" and "pointing down"; "trian" is a triangle and "dmd" is a diamond (rhombus). Note that this mapping of marker shapes to numbers is compatible with the most popular `gnuplot` terminals, but the specific mapping may be different for a given terminal.
"""

# ╔═╡ ea4e84ab-4820-4f91-8782-3bfc3ef4ba6a
md"##### Themes

It is possible to create themes with the `@options` macro:"

# ╔═╡ 1c0d72b4-992a-4a0e-b9bc-24a62a26da02
let
	theme = @options {grid, xlabel = "'x'", ylabel = qs"voltage"}
	@plot(theme, sin)
end

# ╔═╡ 59fd1827-6592-473a-9baf-e17c4c93adb4
md"""A couple of lightweight themes are included:

|Axis themes | Description |
|-----------:|:------------|
| :notics | Removes all tics |
| :labels | Generic axis labels |
| :unitranges | Set all ranges to `[-1:1]` |

Note that `plot` accepts any number of option arguments. Arguments before data are assumed to correspond to `gnuplot` `set` commands; arguments after the data affect the curve attributes.
"""

# ╔═╡ 2c89c62f-e0ca-45fc-8c23-459f40dfc02c
md"To pass a string to gnuplot, it must be be both double-quoted and single-quoted (for example `{title = \"'A plot'\"}`. The `@qs_str` macro helps avoid a bit of typing:"

# ╔═╡ 83d697a8-3a33-4d37-a173-c31309c112e3
md"## Interactivity"

# ╔═╡ afc4dfba-eb72-42de-aec0-d68cf20514be
md"In a notebook, it is easy to tie plot variables to sliders or other UI elements."

# ╔═╡ 8c124c3d-d444-41d6-8187-6058f4b5808f
md"""Frequency: $(@bind freq Slider(1:10, default = 5, show_value = true))"""

# ╔═╡ c2bc72a9-e96d-4216-92dd-71a0e51a647d
md"""Line color: $(@bind color Select(
                   ["'red'" => "red",
                    "'blue'" => "blue",
                    "'orange'" => "orange",
                    "'dark-green'" => "dark green",
                    "'chartreuse'" => "chartreuse"]))"""

# ╔═╡ d253f4ea-b633-4255-8308-e1182c680df2
plot((-1, 1, 200), t -> sin(2π*freq*t), "lw 2 lc $(color)")

# ╔═╡ 6245bfd6-a945-4e84-825d-57fbaa63ffd1
md"## Multiplot"

# ╔═╡ 80e46def-fb34-426a-9883-18a8e99e72ce
md"A multiplot can be easily generated and automatically laid out by adding more axes to an existing figure:"

# ╔═╡ 52e760d6-3848-4705-a9d2-5968e2ad9b03
begin
	f = Figure() # create an empty figure
	plot(sin)
	plot(f[2], cos) # figures are row-major
	plot(f[3], (1:10).^2) # Gaston adjusts the layout as the number of
	plot(f[4], rand(10))  #  suplots grows.
end

# ╔═╡ 91cbc979-b191-45cd-8aba-2ecc31f09a38
md"Add another plot to a subplot using indexing:"

# ╔═╡ 379428f6-1007-457c-95ad-7f090947f72a
plot!(f[4], randn(10))

# ╔═╡ 4779cbbb-9b02-4ffa-b393-c19d0423a967
md"Full control over gnuplot multiplot options can be obtained using margins, as follows:"

# ╔═╡ 6ae49346-1bc5-46dc-9fb1-7530f6606474
let
	f = Figure(multiplot = "title 'Arbitrary multiplot layout demo'")
	x = randn(100)
	y = randn(100)
	@plot({margins = (0.1, 0.65, 0.1, 0.65)},
	      x, y,
	      "w p pt '+' lc 'dark-green'")
	@options histogram(f[2],
	                   {margins = (0.7, 0.9, 0.1, 0.65), tics = false},
	                   y,
	                   {lc = qs"dark-green"},
	                   nbins = 10, horizontal = true)
	@options histogram(f[3],
	                   {margins = (0.1, 0.65, 0.7, 0.9),
	                    boxwidth = "1 relative"},
	                   x,
	                   {lc = "'dark-green'"},
					   nbins = 10)
end

# ╔═╡ c860dea5-1a8a-4516-98d6-97122962345d
md"## Animations

Animations require use of the `gif` or `webp` terminals (make sure your notebook supports the `image/webp` before using it).

Creating an animation is similar to multiplotting: multiple axes are drawn on the same figure. When using the `animate` option of the `gif` or `webp` terminals, however, the plot is rendered as an animation.

Note that `gnuplot` will output a message to STDERR indicating how many frames were recorded; this message is purely informative and not actually an error.

A difficulty arises when mixing plot formats in a notbook (say, `png` and `gif`): the terminal is specified in the global variable `Gaston.config.term`; however, Pluto executes cells in arbitrary order. This means that changing the terminal in one cell may affect other cells.

To solve this problem, `Gaston` provides a way to ignore the global terminal configuration when rendering a plot. A figure `f` can be rendered with a given terminal by calling `animate(f, term)`. The default value of `term` is stored in `Gaston.config.altterm` and defaults to `gif animate loop 0`.

The following examples illustrate how to create and display animations in a notebook:"

# ╔═╡ 5895f542-8a5b-42a4-a1d6-6e4103a71308
let
	f = Figure()
	frames = 20
	x = range(-1, 1, 200)
	ϕ = range(0, 2π-1/frames, frames)
	for i = 1:frames
		plot(f[i], x, sin.(5π*x .+ ϕ[i]), "lw 2")
	end
	animate(f, "gif animate loop 0 size 700,400")
end

# ╔═╡ 4f0391b9-fdf3-48f1-9cb5-9c722ff89c6c
md"A background can be included in an animation as follows:"

# ╔═╡ 42da1eb0-23f6-4f13-8107-a8a6063e87ef
let
	f = Figure()
	frames = 75
	x_bckgnd = range(-1, 1, 200)
	bckgnd = Plot(x_bckgnd, sin.(2π*2*x_bckgnd), "lc 'black'")
	x = range(-1, 1, frames)
	for i in 1:frames
		plot(f[i], x[i], sin(2π*2*x[i]), "w p lc 'orange' pt 7 ps 7")
		push!(f[i], bckgnd)
	end
	for i in frames:-1:1
		plot(f[2frames-i+1], x[i], sin(2π*2*x[i]),
			 "w p lc 'orange' pt 7 ps 7")
		push!(f[2frames-i+1], bckgnd)
	end
	animate(f, "gif animate loop 0 size 700,400")
end

# ╔═╡ Cell order:
# ╟─d4e94a70-866a-46e2-98c2-6babc7745fd2
# ╠═ccdce6f8-f1d8-11ed-19e9-fddf2407113b
# ╠═7076fc20-8f0c-449c-9cfc-edf9801e85cd
# ╠═c55fca39-9251-4593-b7f4-4342119e76e1
# ╠═a64f470c-a8d3-4c28-99f4-8149ac65ff58
# ╠═93d7c222-6755-4b71-b4cb-3ad82f4515f1
# ╠═ff57c40b-615d-4902-9810-8d874220f626
# ╠═dab403c8-f4ae-4029-a8c8-ef5ae161142c
# ╠═a66e7e1d-b3a4-4504-be15-2324808607be
# ╟─1a521882-7ee0-413d-9738-3a025499883e
# ╠═8f50fd19-5ce4-447e-a7f9-7b16d59af6c0
# ╟─ab0aba7c-d841-44bb-8e6a-2e5515ef9aa5
# ╠═0e8236b4-6d1f-46ae-9c0e-ee1d4f605c0d
# ╟─fc31bafd-eb7b-4204-b781-6e06cf95fd25
# ╠═804b8b60-8976-43a3-a5b7-86cedf9118e4
# ╟─e467671a-62a2-406d-99e4-9ecfa7f55b5e
# ╠═a25f483f-f5c7-4949-9690-3d126a12e86a
# ╟─26fe4805-3b08-4750-b0f8-f210a72a502b
# ╠═21e1f17f-4fb2-490e-ade7-77725fb24f61
# ╟─cedb6fa7-e8c7-4a48-8935-1ce6385f1185
# ╠═8a50be7a-bcfa-468c-914a-9b1aa2c970ad
# ╠═6d72504e-fede-41a6-bfef-0aef52936e1b
# ╟─e15e224f-834c-459e-b355-15d1fb8975fb
# ╠═162ccb40-92b0-43fe-a89e-676864ac9883
# ╟─0b229ed3-868a-42d3-b669-6cacaf213c90
# ╠═fbce3eb9-6691-4945-ac6b-4b0bcf31e003
# ╟─262faf7b-ac62-45d9-bc18-3860e6e10fb7
# ╠═57f66b17-8c2d-4737-84e1-c456a7dacc89
# ╟─a0762a24-26be-40a6-a333-92bd8999a5a3
# ╟─d66d3ef3-130f-45a7-81d6-0cac24e9b1d2
# ╠═4f145f29-f99d-4f36-9ebf-5cc632f956c1
# ╠═970fd5da-91e2-44bb-a427-6823b03c79e9
# ╠═881e794d-bc5e-49d0-b240-2cb58abe82ce
# ╠═996ef179-f5fd-4345-a6af-a74709bd2a6b
# ╠═f395e87b-39f6-4f79-83b1-1b44bcb37feb
# ╠═9db5812e-47a3-4b17-b3f0-9e74a38e3f54
# ╠═061a881c-220c-4183-8f5b-12fd91a8f358
# ╠═8c14838e-fcb6-4b49-83cd-a3ef5f267b24
# ╠═be09ba73-cabb-40ce-aa06-6bfe0705f6e2
# ╠═33731005-bb8c-48a9-863a-93e25d579930
# ╠═906770c9-07bd-4447-af21-de487c7a1e02
# ╠═38a71681-dc2d-4af5-be14-1682924abf51
# ╠═5c25b0e3-9a45-4ad5-92ae-314cfce5c117
# ╠═4f4fb009-cf62-4e64-a519-77f340f83f69
# ╠═84ccf2ff-472b-4b34-9472-2006f70684e6
# ╠═b42213a1-f27a-4c96-a6a7-b5a8a200ef19
# ╠═e1e93d06-4565-4625-8fcf-fe8dbc9fe55e
# ╠═8ab2a66a-df03-4aeb-a736-1336b75dadaa
# ╠═ca7554bc-6f9c-4574-bf78-20afd42dc647
# ╠═5acd956b-e22d-4638-be19-1ad090cac7d2
# ╠═20a9dc74-0324-4d76-88fa-1c55ac281e5e
# ╠═a0720ae4-8da5-4ed6-acd9-0471b840fa1d
# ╠═dc989e43-20ad-4f03-86a3-655c00c02a4e
# ╟─564caa1c-222f-4655-9505-162f5e23b234
# ╟─52a654cf-9aac-47ba-82d4-6d7b4320d79e
# ╠═44930880-7dd2-4120-b097-6c19f8e7022a
# ╟─5809cde8-fa4d-49a5-bc4f-4baa0133b21f
# ╠═1b7dfb67-6047-40fa-9b91-c48aa8e8aa9c
# ╟─beb2b6cd-ee6b-4bd8-bf8e-5d071adbd857
# ╟─ea4e84ab-4820-4f91-8782-3bfc3ef4ba6a
# ╠═1c0d72b4-992a-4a0e-b9bc-24a62a26da02
# ╟─59fd1827-6592-473a-9baf-e17c4c93adb4
# ╟─2c89c62f-e0ca-45fc-8c23-459f40dfc02c
# ╟─83d697a8-3a33-4d37-a173-c31309c112e3
# ╟─afc4dfba-eb72-42de-aec0-d68cf20514be
# ╠═8c124c3d-d444-41d6-8187-6058f4b5808f
# ╟─c2bc72a9-e96d-4216-92dd-71a0e51a647d
# ╠═d253f4ea-b633-4255-8308-e1182c680df2
# ╟─6245bfd6-a945-4e84-825d-57fbaa63ffd1
# ╟─80e46def-fb34-426a-9883-18a8e99e72ce
# ╠═52e760d6-3848-4705-a9d2-5968e2ad9b03
# ╟─91cbc979-b191-45cd-8aba-2ecc31f09a38
# ╠═379428f6-1007-457c-95ad-7f090947f72a
# ╟─4779cbbb-9b02-4ffa-b393-c19d0423a967
# ╠═6ae49346-1bc5-46dc-9fb1-7530f6606474
# ╟─c860dea5-1a8a-4516-98d6-97122962345d
# ╠═5895f542-8a5b-42a4-a1d6-6e4103a71308
# ╟─4f0391b9-fdf3-48f1-9cb5-9c722ff89c6c
# ╠═42da1eb0-23f6-4f13-8107-a8a6063e87ef
