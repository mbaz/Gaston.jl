## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Recipes: argument conversion and specialized plot commands

convert_args() = throw(MethodError("Not implemented"))
convert_args3() = throw(MethodError("Not implemented"))

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
convert_args

# 2-D conversions

### 1-argument
# one number
function convert_args(r::R, args... ; pl = "", kwargs...) where R <: Real
    Plot([1], [r], args..., pl)
end

function convert_args(c::C, args... ; pl = "", kwargs...) where C <: Complex
    Plot([real(c)], [imag(c)], args..., pl)
end

# complex vector
function convert_args(c::AbstractVector{<:Complex}, args... ; pl = "", kwargs...) :: Plot
    Plot(collect(real(c)), collect(imag(c)), args..., pl)
end

# functions
function convert_args(f::F, args... ; pl = "", kwargs...) where {F <: Function}
    r = range(-10, 10-1/100, length=100)
    Plot(r, f.(r), args..., pl)
end

### 2-argument
function convert_args(x::R1, y::R2, args... ; pl = "", kwargs...) where {R1 <: Real, R2 <: Real}
    Plot([x], [y], args..., pl)
end

function convert_args(x::Tuple, f::F, args... ; pl = "", kwargs...) where {F<:Function}
    samples = length(x) == 3 ? x[3] : 100
    r = range(x[1], x[2], length=samples)
    Plot(r, f.(r), args..., pl)
end

function convert_args(r::AbstractVector, f::F, args... ; pl = "", kwargs...) where {F<:Function}
    Plot(r, f.(r), args..., pl)
end

# for use with "w image"
function convert_args(a::Matrix{<:Real}, args... ; pl = "", kwargs...)
    x = collect(axes(a,2))
    y = collect(axes(a,1))
    Plot(x, y, a, args..., pl)
end

function convert_args(a::Array{<:Real, 3}, args... ; pl = "", kwargs...)
    x = collect(axes(a, 3))
    y = collect(axes(a, 2))
    Plot(x, y, a[1,:,:], a[2,:,:], a[3,:,:], args..., pl)
end

# histogram
function convert_args(h::Histogram, args... ; pl = "", kwargs...)
    # convert from StatsBase histogram to gnuplot x, y values
    if h.weights isa Vector
        xx = collect(h.edges[1])
        x = (xx[1:end-1]+xx[2:end])./2
        y = h.weights
        return Plot(x, y, args..., pl)
    else
        xx = collect(h.edges[1])
        x = (xx[1:end-1]+xx[2:end])./2
        yy = collect(h.edges[2])
        y = (yy[1:end-1]+yy[2:end])./2
        z = permutedims(h.weights)
        return Plot(x, y, z, args..., pl)
    end
end

### 3-D conversions

function convert_args3(x::R1, y::R2, z::R3, args... ; pl = "", kwargs...) where {R1 <: Real, R2 <: Real, R3 <: Real}
    Plot([x], [y], [z], args..., pl)
end

function convert_args3(a::Matrix{<:Real}; pl = "", kwargs...)
    x = axes(a, 2)
    y = axes(a, 1)
    Plot(x, y, a, args..., pl)
end

function convert_args3(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, f::F, args... ; pl = "", kwargs...) where {F <: Function}
    Plot(x, y, meshgrid(x, y, f), args..., pl)
end

function convert_args3(f::F, args... ; pl = "", kwargs...) where {F <: Function}
    x = y = range(-10, 10, length = 100)
    Plot(x, y, meshgrid(x, y, f), args..., pl)
end

convert_args3(xy::Tuple, f::F, args... ; pl = "", kwargs...) where {F <: Function} = convert_args3(xy, xy, f, args... ; pl=pl, kwargs...)

function convert_args3(xr::Tuple, yr::Tuple, f::F, args... ; pl = "", kwargs...) where {F <: Function}
    samples_x = samples_y = 100
    length(xr) == 3 && (samples_x = xr[3])
    length(yr) == 3 && (samples_y = yr[3])
    xx = range(xr[1], xr[2], length = samples_x)
    yy = range(yr[1], yr[2], length = samples_y)
    Plot(xx, yy, meshgrid(xx, yy, f), args..., pl)
end

### Plot recipes

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
