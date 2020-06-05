# [3-D plotting tutorial](@id threedeetut)

Three dimensional plots can be created with the commands `surf` and `surf!`. These are very similar to [plot](@ref twodeetut), except for the `z` coordinate, which is a matrix that specifies the z-coordinate of the points specified in `x` and `y`.

In addition, the following commands are specialized for different types of 3-D plots:

| Command     | Purpose                          |
|-------------|:---------------------------------|
| `scatter3`, `scatter3!`   | 3-D point clouds   |
| `contour`      | Contour plots                 |
| `heatmap`      | Heatmap plots                 |

## How to plot a set of 3-D coordinates

A set of 3-D coordinates may be explicitly given. Plotting them is just a matter of providing the data to gnuplot. Note that the data may be plotted as a wireframe (with plot style `lines`, which is the default), or as a surface (`pm3d`) with an optional palette.

```@example 3dtut
using Gaston # hide
set(reset=true) # hide
set(termopts="size 550,325 font 'Consolas,11'") # hide
# plot a wireframe
x = [0,1,2,3]
y = [0,1,2]
z = [10 10 10 10 ; 10 5 1 0 ; 10 10 10 10]
surf(x, y, z,
     Axes(title = "'3D: Valley of the Gnu from gnuplot manual'"))
```

Note that the matrix of `z` coordinates is defined so that the columns are indexed by the `x` coordinates. In other words, `z[1,1]` is the surface at `x = 0, y = 0` and `z[3,1]` is the coordinate at `x = 0, y = 2`.

```@example 3dtut
surf(x, y, z, w = :pm3d,
     Axes(title = "'Surface with palette'",
          palette = :summer))
```

## How to plot a 3-D function

A 3-D function defines a surface for a given set of `x` and `y` samples. Consider the function `(x,y) -> @. sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)`. It may be plotted with

```@example 3dtut
x = y = -15:0.4:15
f1 = (x,y) -> @. sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)
surf(x, y, f1, lc = :turquoise,
     Axes(title    = :Sombrero_Wireframe,
          hidden3d = :on))
```

```@example 3dtut
surf(x, y, f1, w = :pm3d,
     Axes(title    = :Sombrero_Surface,
          palette  = :cool,
          cbrange  = (-0.2, 1),
          hidden3d = :on))
```

## Plotting multiple surfaces with `surf!`

The equivalent to `plot!` is `surf!`:

```@example 3dtut
surf(x,y,f1,w=:pm3d,Axes(title=:Sombrero_Surface,palette=:cool,cbrange=(-0.2,1),hidden3d=:on)) # hide
surf!(x, y , (x,y) -> cos.(x./2).*sin.(y./2)-3, lc = :orange, w = :l)
```

## Plotting contours

Gnuplot's contour support is quite flexible. The `contour` command sets up pretty generic contours, which hopefully are useful in many cases. For much more detail, see gnuplot's documentation.

The contours of a surface can be plotted using:

```@example 3dtut
x = y = -5:0.1:5
contour(x, y, (x,y) -> 5cos.(x/2).*sin.(y/2))
```

The labels can be disabled if `labels=false` is passed as an argument:

```@example 3dtut
contour(x, y, (x,y) -> 5cos.(x/2).*sin.(y/2), labels=false)
```

## Plotting heatmaps

Heatmaps can be plotted using `heatmap`. Just like `contour`, this command sets up a pretty basic heatmap; for more control, see gnuplot's documentation.

```@example 3dtut
heatmap(x, y, (x,y)->cos.(x/2).*sin.(y/2))
```
