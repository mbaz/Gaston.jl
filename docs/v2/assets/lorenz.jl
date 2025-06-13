using Gaston
using ColorSchemes

Base.@kwdef mutable struct Lorenz
    dt::Float64 = 0.01
    σ::Float64 = 10
    ρ::Float64 = 28
    β::Float64 = 8/3
    x::Float64 = 1
    y::Float64 = 1
    z::Float64 = 1
end

function step!(l::Lorenz)
    dx = l.σ * (l.y - l.x)
    dy = l.x * (l.ρ - l.z) - l.y
    dz = l.x * l.y - l.β * l.z
    l.x += l.dt * dx
    l.y += l.dt * dy
    l.z += l.dt * dz
    return (l.x, l.y, l.z)
end

Nframes = 120
Npoints = 50
attractor = Lorenz()
x = Float64[];
y = Float64[];
z = Float64[];

s = @gpkw {xrange = (-30, 30),
           yrange = (-30, 30),
           zrange = (0, 60),
           xtics = "offset -1.2,0",
           xtics = "add ('' -30, '' 30)",
           ytics = "offset 1.2,0",
           ytics = "add ('' -30, '' 30)",
           origin = "-0.1, -0.1",
           size = "1.2, 1.2",
           object = "rectangle from screen 0,0 to screen 1,1 fillcolor 'black' behind",
           border = "back lc rgb '#eeeeee' lt 1 lw 1.5",
           view = "equal xyz",
           xyplane = "at 0"}

f = splot(s, 1, 1, 1)

for i = 1:Nframes
    for j = 1:Npoints
        step!(attractor)
        push!(x, attractor.x);
        push!(y, attractor.y);
        push!(z, attractor.z)
    end
    cs = resample(ColorSchemes.inferno, length(x))
    splot(f[i],
          s, "set view 70, $(45 + 17 * sin(2pi * i / Nframes))",
          x, y, z, Gaston.cs2dec(cs),
          "w l notitle lc rgb variable")
end
save(f, filename = "lorenz.webp", term = "webp animate loop 0 size 640,480")
