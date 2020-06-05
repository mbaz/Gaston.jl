# [3-D Gallery](@id threedeegal)

(Many of these examples taken from, or inspired by, [@lazarusa's amazing gallery](https://lazarusa.github.io/gnuplot-examples/gallery/))

# Interlocking Tori

```@example 3dgal
using Gaston # hide
set(reset=true) # hide
set(termopts="size 500,500 font 'Consolas,11'") # hide
U = LinRange(-pi, pi, 100)
V = LinRange(-pi, pi, 20)
x = [cos(u) + .5 * cos(u) * cos(v)      for u in U, v in V]
y = [sin(u) + .5 * sin(u) * cos(v)      for u in U, v in V]
z = [.5 * sin(v)                        for u in U, v in V]
surf(x', y', z',
     w = :pm3d,
     Axes(palette = :dense,
          pm3d = "depthorder",
          colorbox = :off,
          key = :false,
          tics = :false,
          border = 0,
          view = "60, 30, 1.5, 0.9",
          style = "fill transparent solid 0.7"))
x = [1 + cos(u) + .5 * cos(u) * cos(v)  for u in U, v in V]
y = [.5 * sin(v)                        for u in U, v in V]
z = [sin(u) + .5 * sin(u) * cos(v)      for u in U, v in V]
surf!(x', y' ,z' , w = :pm3d)
```

# Fill a curve in 3-D

```@example 3dgal
set(saveopts="size 550,325 font 'Consolas,11'") # hide
x = 0.:0.05:3;
y = 0.:0.05:3;
z = @. sin(x) * exp(-(x+y))
surf(x, y, z, supp = [z.*0 z], curveconf = "w zerror t 'Data'", lw = 3,
     Axes(xlabel = :X, ylabel = :Y,
          linetype = :Set1_5,
          style = "fill transparent solid 0.3",
          xyplane = "at 0",
          grid = :on)
    )
surf!(x.*0, y, z, w = :l, lw = 3)
surf!(x, y.*0, z, w = :l, lw = 3)
```

# Surface with contours

```@example 3dgal
x = y = -10:0.5:10
f1 = (x,y) -> cos.(x./2).*sin.(y./2)
surf(x, y, f1,
     lc = :turquoise,
     Axes(hidden3d = :on,
          contour = "base",
          cntrparam = "levels 10",
          key = :off))
```

# Egg-shaped contours

```@example 3dgal
x = -1:0.05:1
y = -1.5:0.05:2
egg(x,y) = x^2 + y^2/(1.4 + y/5)^2
segg = [egg(x,y) for x in x, y in y]
contour(x, y, segg', labels = false,
        curveconf = "w l lc palette",
        Axes(palette = :cool,
             cntrparam = "levels incremental 0,0.01,1",
             auto = "fix",
             xrange = (-1.2, 1.2),
             yrange = (-1.5, 2),
             cbrange = (0, 1),
             xlabel = :x,
             ylabel = :y,
             size="ratio -1"))
```

# Tubes

```@example 3dgal
U  = LinRange(0,10π, 80)
V = LinRange(0,2π, 20)
x = [(1-0.1*cos(v))*cos(u) for u in U, v in V]
y = [(1-0.1*cos(v))*sin(u) for u in U, v in V]
z = [0.1*(sin(v) + u/1.7 - 10) for u in U, v in V]
surf(x, y, z, w="pm3d",
     Axes(pm3d = "depthorder",
     style = "fill transparent solid 0.7",
     view = "equal xyz",
     xyplane = -0.05,
     palette = :ice,
     xrange = (-1.2, 1.2),
     yrange = (-1.2, 1.2),
     colorbox = :off))
```

# Spheres

```@example 3dgal
Θ = LinRange(0, 2π, 100) # 50
Φ = LinRange(0, π, 20)
r = 0.8
x = [r * cos(θ) * sin(ϕ)      for θ in Θ, ϕ in Φ]
y = [r * sin(θ) * sin(ϕ)      for θ in Θ, ϕ in Φ]
z = [r * cos(ϕ) for θ in Θ, ϕ in Φ]
surf(x, y, z, w = :l, lc = :turquoise,
     Axes(view = "equal xyz",
          pm3d = "depthorder",
          hidden3d = :on))
```

```@example 3dgal
surf(x, y, z, w = :pm3d,
     Axes(style = "fill transparent solid 0.5",
     xyplane = 0,
     palette = :summer,
     view = "equal xyz",
     pm3d = "depthorder"))
```

# Torus

```@example 3dgal
U  = LinRange(-π,π, 50)
V = LinRange(-π,π, 100)
r = 0.5
x = [1 + cos(u) + r * cos(u) * cos(v)  for u in U, v in V]
y = [r * sin(v)                        for u in U, v in V]
z = [sin(u) + r * sin(u) * cos(v)      for u in U, v in V]
axesconf = """set object rectangle from screen 0,0 to screen 1,1 behind fillcolor 'black' fillstyle solid noborder
              set pm3d depthorder
              set style fill transparent solid 0.5
              set pm3d lighting primary 0.05 specular 0.2
              set view 108,2
              unset border
              set xyplane 0
              unset tics
              unset colorbox"""
surf(x, y, z, w = :pm3d, Axes(palette = :cool, axesconf = axesconf))
```

# Animation

```julia
closeall()  # hide
z=0:0.1:10pi;
step = 5;
cc = "w l lc 'turquoise' lw 3 notitle"
ac = Axes(zrange = (0,30), xrange = (-1.2, 1.2), yrange = (-1.2, 1.2),
          tics = :off,
          xlabel = :x, ylabel = :y, zlabel = :z)
F = scatter3(cos.(z[1:step]), sin.(z[1:step]), z[1:step], curveconf = cc, ac);
for i = 2:60
    pi = scatter3(cos.(z[1:i*step]), sin.(z[1:i*step]), z[1:i*step],
                  curveconf = cc, ac, handle = 2);
    push!(F, pi)
end
for i = 60:-1:1
    pi = scatter3(cos.(z[1:i*step]), sin.(z[1:i*step]), z[1:i*step],
                  curveconf = cc, ac, handle = 2);
    push!(F, pi)
end
save(term="gif", saveopts = "animate size 600,400 delay 1", output="anim3d.gif", handle=1)
```

![](assets/anim3d.gif)

```julia
closeall() # hide
x = y = -15:0.4:15
ac = Axes(title = :Sombrero_Surface,
          palette  = :cool,
          cbrange  = (-0.2, 1),
          zrange   = (-0.3, 1),
          hidden3d = :on)
F = surf(x, y, (x,y) -> (@. sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)),
         ac, w = :pm3d);
for i = 1:-0.1:-1
    pi = surf(x, y, (x,y) -> (@. i*sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)),
              ac, w = :pm3d, handle = 2);
    push!(F, pi)
end
for i = -0.9:0.1:1
    pi = surf(x, y, (x,y) -> (@. i*sin(sqrt(x*x+y*y))/sqrt(x*x+y*y)),
              ac, w = :pm3d, handle = 2);
    push!(F, pi)
end
save(term = "gif", saveopts = "animate size 600,400 delay 1",
     output = "anim3db.gif", handle=1)
```

![](assets/anim3db.gif)
