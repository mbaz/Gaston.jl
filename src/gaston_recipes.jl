## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Recipes: argument conversion and specialized plot commands

"""
    convert_args(...)

Convert values of specific types to data that gnuplot can plot.

Users should add methods to this function for their own types. These
methods must return a tuple of two sets of coordinates, `x` and `y`.

# Example:

```
julia> struct Data
           x
           y
       end

julia> data = Data(1:10, rand(10))
julia> plot(data)
ERROR: MethodError: no method matching ndims(::Data)
```
To plot `data::Data`, a method must be added to `convert_args`:
```
Gaston.convert_args(d::Data) = d.x, d.y
```
Now, `plot(data)` works as expected.

See also: [`convert_args3`](@ref).
"""
convert_args() = throw(MethodError("Not implemented"))

const SoS = Union{String, Symbol, Vector{<:Pair}}

struct TimeSeries{P <: SoS, N}
    ts   :: NTuple{N, Array{<:Real}}
    pl   :: P
    is3d :: Bool
end

TimeSeries(ts... ; pl = "", is3d = false) = TimeSeries(collect.(ts), parse_plotline(pl), is3d)

struct TSBundle{P <: SoS, N}
    series   :: NTuple{N, TimeSeries}
    settings :: P
end

TSBundle(b::TimeSeries... ; settings = "") = TSBundle(b, parse_settings(settings))

struct PlotObject
    bundles     :: Tuple{Vararg{TSBundle{<:SoS}}}
    mp_settings :: String
end

PlotObject(; kwargs...) = throw(MethodError("At least one argument is required"))

PlotObject(ts::TimeSeries... ; mp_settings = "") = PlotObject(TSBundle(ts...); mp_settings)

PlotObject(bs::TSBundle... ; mp_settings = "") = PlotObject(bs, mp_settings)

function show(io::IO, b::TSBundle)
    println(io, "TSBundle:")
    println(io, "  with settings: \"$(b.settings)\"")
    println(io, "  and $(length(b.series)) time series.")
end

function show(io::IO, po::PlotObject)
    println(io, "PlotObject:")
    println(io, "  with multiplot settings: \"$(po.mp_settings)\"")
    _bb = length(po.bundles) > 1 ? "bundles" : "bundle"
    println(io, "  and $(length(po.bundles)) $(_bb).")
    for (i, b) in enumerate(po.bundles)
        println(io, "    Bundle $i:")
        println(io, "      with settings: \"$(b.settings)\"")
        println(io, "      and $(length(b.series)) time series:")
        for (j, ts) in enumerate(b.series)
            println(io, "        Time series $j with plotline \"$(ts.pl)\"")
        end
    end
end

# 2-D conversions

# 1-argument
function convert_args(y::R) where {R <: Real}
    PlotObject( TimeSeries([1], [y]) )
end

function convert_args(x::Vector{<:Real})
    PlotObject( TimeSeries(firstindex(x):lastindex(x), x) )
end

function convert_args(x::AbstractRange{<:Real})
    PlotObject( TimeSeries(firstindex(x):lastindex(x), x) )
end

function convert_args(x::Vector{<:Complex})
    PlotObject( TimeSeries(real(x), imag(x)) )
end

function convert_args(x::F) where {F <: Function}
    r = range(-10, 10-1/100, length=100)
    PlotObject( TimeSeries(r, x.(r)) )
end

# 2-argument
function convert_args(x::R1, y::R2) where {R1 <: Real, R2 <: Real}
    PlotObject( TimeSeries([x], [y]) )
end

function convert_args(y::Tuple, x::F) where {F<:Function}
    samples = length(y) == 3 ? y[3] : 100
    r = range(y[1], y[2], length=samples)
    PlotObject( TimeSeries(r, x.(r)) )
end

function convert_args(r::AbstractVector, x::F) where {F<:Function}
    PlotObject( TimeSeries(r, x.(r)) )
end

# for use with "w image"
function convert_args(a::Matrix{<:Real})
    x = collect(axes(a,2))
    y = collect(axes(a,1))
    PlotObject( TimeSeries(x, y, a) )
end

function convert_args(a::Array{<:Real, 3})
    x = collect(axes(a, 3))
    y = collect(axes(a, 2))
    PlotObject( TimeSeries(x, y, a[1,:,:], a[2,:,:], a[3,:,:]) )
end

# histogram
function convert_args(h::Histogram)
    # convert from StatsBase histogram to gnuplot x, y values
    if h.weights isa Vector
        xx = collect(h.edges[1])
        x = (xx[1:end-1]+xx[2:end])./2
        y = h.weights
        return PlotObject( TimeSeries(x, y) )
    else
        xx = collect(h.edges[1])
        x = (xx[1:end-1]+xx[2:end])./2
        yy = collect(h.edges[2])
        y = (yy[1:end-1]+yy[2:end])./2
        z = permutedims(h.weights)
        return PlotObject( TimeSeries(x, y, z) )
    end
end

# 3-D conversions
convert_args3() = throw(MethodError("Not implemented"))

function convert_args3(x::R1, y::R2, z::R3) where {R1 <: Real, R2 <: Real, R3 <: Real}
    PlotObject( TimeSeries([x], [y], [z], is3d = true) )
end

function convert_args3(x::R1, y::R2, z::R3, x1::R4, y1::R5, z1::R6) where
    {R1 <: Real, R2 <: Real, R3 <: Real, R4 <: Real, R5 <: Real, R6 <: Real}
    PlotObject( TimeSeries([x], [y], [z], [x1], [y1], [z1], is3d = true) )
end

function convert_args3(a::Matrix{<:Real})
    x = axes(a, 2)
    y = axes(a, 1)
    PlotObject( TimeSeries(x, y, a, is3d = true) )
end

function convert_args3(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, z::Matrix{<:Real})
    PlotObject( TimeSeries(x, y, z, is3d = true) )
end

function convert_args3(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, f::F) where {F <: Function}
    PlotObject( TimeSeries(x, y, meshgrid(x, y, f), is3d = true) )
end

function convert_args3(f::F) where {F <: Function}
    x = y = range(-10, 10, length = 100)
    PlotObject( TimeSeries(x, y, meshgrid(x, y, f), is3d = true) )
end

convert_args3(xy::Tuple, f::F) where {F <: Function} = convert_args3(xy, xy, f)

function convert_args3(xr::Tuple, yr::Tuple, f::F) where {F <: Function}
    samples_x = samples_y = 100
    length(xr) == 3 && (samples_x = xr[3])
    length(yr) == 3 && (samples_y = yr[3])
    xx = range(xr[1], xr[2], length = samples_x)
    yy = range(yr[1], yr[2], length = samples_y)
    PlotObject( TimeSeries(xx, yy, meshgrid(xx, yy, f), is3d = true) )
end

#= Attempt to create a recipe (with a macro or with a function -- both work)
macro recipe(name, theme)
    escname = esc(name)
    :( function $escname(args... ; kwargs...)
            args, plotline = _getplotline(args...)
            s = merge(themes[$theme].settings, NamedTuple(kwargs),)
            p = themes[$theme].plotline * " " * plotline
            plot(args..., p ; s...)
        end
    )
end

function recipe(theme)
    (args... ; kwargs...) -> begin
        args, plotline = _getplotline(args...)
        s = merge(themes[theme].settings, NamedTuple(kwargs),)
        p = themes[theme].plotline * " " * plotline
        plot(args..., p ; s...)
    end
end

themedplot(theme) = let theme = theme
                        f(args... ; kwargs...)::Figure = plot(args... ; kwargs..., theme = theme)
                    end

themedplot!(theme) = let theme = theme
                         f(args... ; kwargs...)::Figure = plot!(args... ; kwargs..., theme = theme)
                     end
=#

scatter(args... ; kwargs...) = plot(args... ; kwargs..., ptheme = :scatter)
scatter!(args... ; kwargs...) = plot!(args... ; kwargs..., ptheme = :scatter)

function stem(args... ; onlyimpulses = false, color = "'blue'", kwargs...)
    clr = color != "" ? "linecolor $(color)" : ""
    plot(args..., clr; kwargs..., ptheme = :impulses)
    if !onlyimpulses
        plot!(args..., clr ; kwargs..., ptheme = :stem)
    end
    figure()
end

function stem!(args... ; onlyimpulses = false, color = "'blue'", kwargs...)
    clr = color != "" ? "linecolor $(color)" : ""
    plot!(args..., clr; kwargs..., ptheme = :impulses)
    if !onlyimpulses
        plot!(args..., clr ; kwargs..., ptheme = :stem)
    end
end

"""
    bar([x,] y, [axes,] args...) -> Gaston.Figure

Generate a bar plot with axes configuration `axes`.
"""
bar(args... ; kwargs...) = plot(args... ; kwargs..., stheme = :boxplot, ptheme = :box)
bar!(args... ; kwargs...) = plot!(args... ; kwargs..., ptheme = :box)

barerror(args... ; kwargs...) = plot(args... ; kwargs..., stheme = :boxplot, ptheme = :boxerror)
barerror!(args... ; kwargs...) = plot!(args... ; kwargs..., ptheme = :boxerror)

## Histograms
"""
    histogram(data, [axes,] bins=10, mode = :none, args...) -> Gaston.Figure

Plot a histogram of `data`. `bins` specifies the number of bins (default 10);
the histogram area is normalized according to `mode` (default `:none`).
"""
function histogram(args... ;
                   edges                = nothing,
                   nbins                = 10,
                   mode       :: Symbol = :pdf,
                   horizontal :: Bool   = false,
                   kwargs...)
    # Extract data and non-data from args...
    data = []
    front = []
    back = []
    i = 1
    while i <= length(args)
        a = args[i]
        if typeof(a) in (Axis, Figure, FigureAxis, String, Symbol) || a isa Vector{T} where T<:Pair
            push!(front, a)
            i = i + 1
        else
            break
        end
    end
    while i <= length(args)
        a = args[i]
        if !(typeof(a) in (Axis, Figure, FigureAxis, String, Symbol) || a isa Vector{T} where T<:Pair)
            push!(data, a)
            i = i + 1
        else
            break
        end
    end
    while i <= length(args)
        a = args[i]
        if typeof(a) in (Axis, Figure, FigureAxis, String, Symbol) || a isa Vector{T} where T<:Pair
            push!(back, a)
            i = i + 1
        else
            break
        end
    end
    if length(data) == 1
        h = edges === nothing ? hist(data[1] ; nbins, mode) : hist(data[1] ; edges, mode)
        if horizontal
            return plot(front..., h, back... ; kwargs..., stheme = :histplot, ptheme = :horhist)
        else
            return plot(front..., h, back... ; kwargs..., stheme = :histplot, ptheme = :box)
        end
    else
        nbins isa Number && (nbins = (nbins, nbins))
        h = edges === nothing ? hist(data[1], data[2] ; nbins, mode) :
                                hist(data[1], data[2] ; edges, mode)
        return plot(front..., h, back... ; kwargs..., ptheme = :image)
    end
end

"""
    imagesc([x,] [y,] z, [axes,] args...) -> Gaston.Figure

Plot an image given by array `z`. If the array is a matrix, a grayscale image
is assumed. If the array is three-dimensional, an rgbimage is assumed, with
`z[1,:,:]` the red channel, `z[2,:,:]` the blue channel, and `z[3,:,:]` the
blue channel.
"""
function imagesc(args... ; kwargs...)
    rgb = false
    for a in args
        if a isa AbstractArray && ndims(a) == 3
            rgb = true
            break
        end
    end
    if rgb
        plot(args... ; kwargs..., stheme = :imagesc, ptheme = :rgbimage)
    else
        plot(args... ; kwargs..., stheme = :imagesc, ptheme = :image)
    end
end

### 3-D recipes

## Wireframes
wireframe(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :hidden3d)
wireframe!(args... ; kwargs...) = splot!(args... ; kwargs...)

## Surfaces
surf(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :hidden3d, ptheme = :pm3d)
surf!(args... ; kwargs...) = splot!(args... ; kwargs..., ptheme = :pm3d)

# Surface with contours on the base
function surfcontour(args... ; labels = true, kwargs...)
    splot(args... ; kwargs..., stheme = :contourproj)
    if labels
        splot!(args... ; kwargs..., ptheme = :labels)
    end
    figure()
end

# surface with superimposed wireframe
wiresurf(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :wiresurf)
wiresurf!(args... ; kwargs...) = splot!(args... ; kwargs...)

# 3D scatter plots
scatter3(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :scatter3, ptheme = :scatter)
scatter3!(args... ; kwargs...) = splot!(args... ; kwargs..., ptheme = :scatter)

"""
    contour([x,] [y,] z::Matrix, labels = true, [axes,] args...) -> Gaston.Figure

Plot the contour lines given by the surface `z`. If `labels = false`, no labels
are included in the plot.

    contour(x, y, f::Function, args...) -> Gaston.Figure

Plot the contours of the surface `f.(x,y)`.
"""
function contour(args... ; labels = true, kwargs...)
    splot(args... ; kwargs..., stheme = :contour)
    if labels
        splot!(args... ; kwargs..., ptheme = :labels)
    end
    figure()
end

"""
    heatmap(x, y, z::Matrix, [axes,] args...)

Plot the heatmap of the surface specified by `z`.
"""
heatmap(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :heatmap, ptheme = :pm3d)
