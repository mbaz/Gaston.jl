# 3-D plots



## Explicit `x`, `y` and `z` coordinates

The first way to obtain a 3-D plot is by giving explicit x, y and z coordinates to `surf`.

```@example t1
using Gaston # hide
set(mode="ijulia") # hide
set(size="500,400") # hide
nothing # hide
x=[0,1,2,3]
y=[0,1,2]
Z=[10 10 10; 10 5 10; 10 1 10; 10 0 10]
surf(x, y, Z, title = "3D: Valley of the Gnu from gnuplot manual")
```

The default plostyle is to plot a mesh with points joined by lines, as seen above.

## `z` coordinates defined by a function

Alternatively, a function may be provided that takes the `x`, `y` coordinates as arguments and returns a `z` coordinate.

```@example t1
x = y = -15:0.33:15
surf(x, y, (x,y)->sin.(sqrt.(x.*x+y.*y))./sqrt.(x.*x+y.*y),
    title="Sombrero", plotstyle="pm3d")
```

## Plotting multiple surfaces with `surf!`

The equivalent to `plot!` is `surf!`:

```@example t1
x = y = -10:0.5:10
surf(x, y, (x,y)->2sin.(sqrt.(x.*x+y.*y))./sqrt(x.*x+y.*y)-2,
    title="Two 3D plots in a single figure",
    plotstyle="lines", linecolor="magenta", gpcom="unset colorbox")
surf!(x,y,(x,y)->cos.(x/2).*sin.(y/2)+3,plotstyle="pm3d")
```

## Changing the palette

The palette of a 3-D plot with `pm3d` plotstyle can be controlled with the `palette` setting.

```@example t1
surf(x, y, (x,y)->sin.(sqrt(x.*x+y.*y))./sqrt.(x.*x+y.*y),
     title="Sombrero", plotstyle="pm3d", palette="gray")
```

## Plotting contours

Gnuplot's contour support is quite flexible. Currently, Gaston exposes just basic contour functionality with little room for configuration.

A contour for the current surface can be plot using `gpcom="set contour base"`:

```@example t1
gp = "set contour base; unset key"
surf(x, y, (x,y)->5cos.(x/2).*sin.(y/2), font=",10", gpcom=gp)
```

The `contour` command plots just the contour lines, not the surface:

```@example t1
x = y = -5:0.1:5;
contour(x, y, (x,y)->5cos.(x/2).*sin.(y/2))
```

The labels can be disabled if `labels=false` is passed as an argument:

```@example t1
contour(x, y, (x,y)->5cos.(x/2).*sin.(y/2), labels=false)
```

## Plotting heatmaps

Gaston does not expose a direct interface for plotting heatmaps, but these are easily achieved by setting gnuplot's `view` to `map` using `gpcom`:

```@example t1
surf(x, y, (x,y)->cos.(x/2).*sin.(y/2), plotstyle="pm3d", gpcom="set view map")
```
