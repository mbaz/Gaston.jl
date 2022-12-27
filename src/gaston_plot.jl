# 2D plots
"""
    plot([x,] y, [z,] [axes,] [supp,] [dims,] [h,] [curve]) -> Gaston.Figure

Plots data `x`, `y`, and optionally `z` and `supp`, in two or three dimensions
as specified by `dims`, with axes configuration `axes`, and curve configuration
`curve`, on the figure with handle `h`.

If `x` is omitted, then `x=1:length(t)` is assumed.

    plot(x, f::Function, args...) -> Gaston.Figure

Assume `y = f.(x)`.

    plot(c, args...) -> Gaston.Figure

If `c` is a complex vector, plot its real part vs its imaginary part.

    plot(P::Matrix{Union{Gaston.Figure}, Nothing}) -> Gaston.Figure

Create a 'muliplot' with the layout in `P`. Returns a new figure.
"""
function plot(x::Coord, y::Coord, z::Coord = nothing, axes::Axes = Axes() ;
              supp::Coord = nothing,
              dims::Int   = 2,
              handle      = gnuplot_state.current,
              args...)

    ## Process optional keyword arguments.
    axesconf = gparse(axes)
    curveconf = gparse(args)

    # create curve
    c = Curve(x, y, z, supp, curveconf)

    # push curve we just created to current figure
    # create new figure
    fig = newfigure(handle)
    push!(fig, Plot(dims=dims, axesconf = axesconf, curves = [c]))
    #fig.subplots[1] = Plot(dims=dims, axesconf = axesconf, curves = [c])

    # write gnuplot data to file
    write_data(c, fig.subplots[1].dims, fig.subplots[1].datafile)

    return fig
end

### Alternative `plot` methods
plot(y, a::Axes = Axes() ; args...) = plot(1:length(y), y, nothing, a ; args...)
plot(x, y, a::Axes = Axes() ; args...) = plot(x, y, nothing, a ; args...)
## Complex vector
plot(c::ComplexCoord, a::Axes = Axes() ; args...) = plot(real(c), imag(c), nothing, a ; args...)
## Function
plot(x, f::Function, a::Axes = Axes() ; args...) = plot(x, f.(x), nothing, a ; args...)

# Add a curve to an existing figure
"""
plot!(x, y [, z] [,supp] [, dims] [, h] [, curve...]) -> Gaston.Figure

Adds the curve specified by data `x`, `y`, and optionally `z` and `supp`, in
two or three dimensions as specified by `dims`, and curve configuration
`curve`, to the figure with handle `h`.
"""
function plot!(x::Coord, y::Coord, z::Coord = nothing;
               supp::Coord = nothing,
               dims::Int   = 2,
               handle      = gnuplot_state.current,
               args...)

    # Process optional keyword arguments.
    curveconf = gparse(args)

    # determine handle
    handles = gethandles()
    handle ∈ handles || error("Cannot append curve to non-existing handle")

    # create curve
    c = Curve(x, y, z, supp, curveconf)

    # push new curve to current figure
    fig = gnuplot_state.figs[findfigure(handle)]
    push!(fig, c)

    # write gnuplot data to a file
    write_data(c, fig.subplots[1].dims, fig.subplots[1].datafile, append=true)

    return fig
end

### Alternative `plot!` methods
# Omit `x` coordinate
plot!(y ; args...) = plot!(1:length(y), y ; args...)
# Complex vector
plot!(c::ComplexCoord ; args...) = plot!(real(c), imag(c) ; args...)
# Function
plot!(x, f::Function ; args...) = plot!(x, f.(x) ; args...)

### Multiplot
function plot(P::FigArray ; handle::Int = 0)
    # Create new figure
    fig = newfigure(handle)
    if P isa Vector
        fig.layout = (size(P)[1], 1)
    else
        fig.layout = size(P)
    end
    for p in P
        if p isa Figure
            push!(fig, p.subplots[1])
        else
            push!(fig, nothing)
        end
    end
    return fig
end
