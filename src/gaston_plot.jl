# 2D plots
function plot(x::Coord, y::Coord, z::Coord = nothing, axis::Axis = Axis() ;
              supp::Coord = nothing,
              dims::Int   = 2,
              handle      = gnuplot_state.current,
              args...)

    ## Process optional keyword arguments.
    axisconf = parse(axis)
    curveconf = parse(args)

    # create curve
    c = Curve(x, y, z, supp, curveconf)

    # push curve we just created to current figure
    # create new figure
    fig = newfigure(handle)
    push!(fig, Plot(dims=dims, axisconf = axisconf, curves = [c]))
    #fig.subplots[1] = Plot(dims=dims, axisconf = axisconf, curves = [c])

    # write gnuplot data to file
    write_data(c, fig.subplots[1].dims, fig.subplots[1].datafile)

    return fig
end

### Alternative `plot` methods
plot(y, a::Axis = Axis() ; args...) = plot(1:length(y), y, nothing, a ; args...)
plot(x, y, a::Axis = Axis() ; args...) = plot(x, y, nothing, a ; args...)
## Complex vector
plot(c::ComplexCoord, a::Axis = Axis() ; args...) = plot(real(c), imag(c), nothing, a ; args...)
## Function
plot(x, f::Function, a::Axis = Axis() ; args...) = plot(x, f.(x), nothing, a ; args...)

# Add a curve to an existing figure
function plot!(x::Coord, y::Coord, z::Coord = nothing;
               supp::Coord = nothing,
               dims::Int   = 2,
               handle      = gnuplot_state.current,
               args...)

    # Process optional keyword arguments.
    curveconf = parse(args)

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
function plot(P::FigArray)
    # Create new figure
    handle = figure()
    fig = gnuplot_state.figs[findfigure(handle)]
    fig.layout = size(P)
    for p in P
        if p isa Figure
            push!(fig, p.subplots[1])
        else
            push!(fig, nothing)
        end
    end
    return fig
end
