## Copyright (c) 2013 Miguel Bazdresch
##
## This file is distributed under the 2-clause BSD License.

# Recipes: argument conversion and specialized plot commands

"""
    convert_args(args...)

Convert values of specific types to data that gnuplot can plot.

Users should add methods to this function for their own types. The returned value
must be one of the following types:

* A `Gaston.Plot`, which describes a curve (i.e. it contains coordinates and a plotline).
* A `Gaston.Axis`, which may contain multiple `Plot`s and axis settings.
* A tuple with the following fields:
  * `axes`: a vector of `Gaston.Axis`
  * `multiplot`, a string to be passed to `set multiplot`
  * `autolayout::Bool`, set to `true` if Gaston should control the axes layout.

See the Gaston documentation for full details and examples.

To add a recipe for 3-D plotting, use `convert_args3`.
"""
convert_args

"""
    convert_args3(args...)

Convert values of specific types to data that gnuplot can plot using `splot`.

See documentation for `convert_args` for more details.
"""
convert_args3

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

function convert_args3(a::Matrix{<:Real} ; pl = "", kwargs...)
    x = axes(a, 2)
    y = axes(a, 1)
    Plot(x, y, a, pl)
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

"""
    scatter(args...; kwargs...)::Figure

Generate a scatter plot with built-in plotline theme `scatter`.

See the `plot` documentation for more information on the arguments.
"""
scatter(args... ; kwargs...) = plot(args... ; kwargs..., ptheme = :scatter)

"""
    scatter!(args...; kwargs...)::Figure

Insert a scatter plot. See the `scatter` documentation for more details.
"""
scatter!(args... ; kwargs...) = plot!(args... ; kwargs..., ptheme = :scatter)

"""
    stem(args...; onlyimpulses::Bool = false, color = "'blue'", kwargs...)::Figure

Generate a stem plot with built-in plotline themes `impulses` and `stem`.

This function takes the following keyword arguments:

* `onlyimpulses`: if `true`, plot using only impulses and omit the dots.
* `color`: specify line color to use. If not specified, the impulses and
  the dots may be plotted with different colors.

See the `plot` documentation for more information on the arguments.
"""
function stem(args... ; onlyimpulses = false, color = "'blue'", kwargs...)
    clr = color != "" ? "linecolor $(color)" : ""
    plot(args..., clr; kwargs..., ptheme = :impulses)
    if !onlyimpulses
        plot!(args..., clr ; kwargs..., ptheme = :stem)
    end
    figure()
end

"""
    stem!(args... ; onlyimpulses = false, color = "'blue'", kwargs...)::Figure

Insert a stem plot. See the `stem` documentation for more details.
"""
function stem!(args... ; onlyimpulses = false, color = "'blue'", kwargs...)
    clr = color != "" ? "linecolor $(color)" : ""
    plot!(args..., clr; kwargs..., ptheme = :impulses)
    if !onlyimpulses
        plot!(args..., clr ; kwargs..., ptheme = :stem)
    end
end

"""
    bar(args...; kwargs...)::Figure

Generate a bar plot with built-in settings theme `boxplot` and plotline theme `box`.
See the `plot` documentation for more information on the arguments.
"""
bar(args... ; kwargs...) = plot(args... ; kwargs..., stheme = :boxplot, ptheme = :box)

"""
    bar!(args...; kwargs...)::Figure

Insert a bar plot. See the `bar` documentation for more details.
"""
bar!(args... ; kwargs...) = plot!(args... ; kwargs..., ptheme = :box)

"""
    barerror(args...; kwargs...)::Figure

Generate a barerror plot with built-in settings theme `boxplot` and plotline theme
`boxerror`. See the `plot` documentation for more information on the arguments.
"""
barerror(args... ; kwargs...) = plot(args... ; kwargs..., stheme = :boxplot, ptheme = :boxerror)

"""
    barerror!(args...; kwargs...)::Figure

Insert a barerror plot. See the `barerror` documentation for more details.
"""
barerror!(args... ; kwargs...) = plot!(args... ; kwargs..., ptheme = :boxerror)

## Histograms
"""
    histogram(args...,[bins = 10,] [mode = :pdf,] [edges = nothing,] [horizontal = false]; kwargs...)::Figure

Plot a histogram of the provided data, using `StatsBase.fit`. This function takes
the following keyword arguments:

* `bins` specifies the number of bins (default 10)
* `mode` specifies how the histogram area is normalized (see `StatsBase.fit`)
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
    imagesc(args...; kwargs...)::Figure

Plot an array as an image. If the array is a matrix, a grayscale image is
assumed. If the given array `z` is three-dimensional, an rgbimage is assumed,
with `z[1,:,:]` the red channel, `z[2,:,:]` the blue channel, and `z[3,:,:]`
the blue channel.

See the documentation to `plot` for more details.
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

"""
    wireframe(args...; kwargs...)::Figure

Plot the provided data using a wireframe, using the settings theme `hidden3d`.

See the `plot` documentation for more information on the arguments.
"""
wireframe(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :hidden3d)

"""
    wireframe!(args...; kwargs...)::Figure

Insert a wireframe plot. See the `wireframe` documentation for more details.
"""
wireframe!(args... ; kwargs...) = splot!(args... ; kwargs...)

## Surfaces

"""
    surf(args...; kwargs...)::Figure

Plot the provided data as a surface, using the settings theme `hidden3d` and the
plotline theme `pm3d`.

See the `plot` documentation for more information on the arguments.
"""
surf(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :hidden3d, ptheme = :pm3d)

"""
    surf!(args...; kwargs...)::Figure

Insert a surface plot. See the `surf` documentation for more details.
"""
surf!(args... ; kwargs...) = splot!(args... ; kwargs..., ptheme = :pm3d)

# Surface with contours on the base

"""
    surfcontour(args...; [labels::Bool = true,] kwargs...)::Figure

Plot the provided data as a surface with contour lines at the base, using the
settings theme `contourproj` and the plotline theme `labels`.

If the keyword argument `labels` is `true`, then numerical labels are added to
the contour lines.

See the `plot` documentation for more information on the arguments.
"""
function surfcontour(args... ; labels = true, kwargs...)
    splot(args... ; kwargs..., stheme = :contourproj)
    if labels
        splot!(args... ; kwargs..., ptheme = :labels)
    end
    figure()
end

# surface with superimposed wireframe

"""
    wiresurf(args...; kwargs...)::Figure

Plot the provided data as a surface with a superimposed wireframe, using the
settings theme `wiresurf`.

See the `plot` documentation for more information on the arguments.
"""
wiresurf(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :wiresurf)

"""
    wiresurf!(args...; kwargs...)::Figure

Insert a wiresurf plot. See the `wiresurf` documentation for more details.
"""
wiresurf!(args... ; kwargs...) = splot!(args... ; kwargs...)

# 3D scatter plots

"""
    scatter3(args...; kwargs...)::Figure

Generate a scatter plot of the provided data, using the settings theme `scatter3` and the
plotline theme `scatter`.

See the `plot` documentation for more information on the arguments.
"""
scatter3(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :scatter3, ptheme = :scatter)

"""
    scatter3!(args...; kwargs...)::Figure

Insert a scatter plot. See the `scatter3` documentation for more details.
"""
scatter3!(args... ; kwargs...) = splot!(args... ; kwargs..., ptheme = :scatter)

"""
    contour(args...; [labels::Bool = true,] kwargs...)::Figure

Plot the provided data using contour lines, with settings themes `countour` and `labels`.

If the keyword argument `labels` is `true`, then the contour lines are labeled.
See the documentation to `plot` for more details.
"""
function contour(args... ; labels = true, kwargs...)
    splot(args... ; kwargs..., stheme = :contour)
    if labels
        splot!(args... ; kwargs..., ptheme = :labels)
    end
    figure()
end

"""
    heatmap(args...; kwargs...)

Plot the data provided as a heatmap, using the settings theme `heatmap` and the
plotline theme `pm3d`.

See the documentation to `plot` for more details.
"""
heatmap(args... ; kwargs...) = splot(args... ; kwargs..., stheme = :heatmap, ptheme = :pm3d)
