# 2D plots
function plot(x::Coord, y::Coord, z::Coord = Coord(), axis::Axis = Axis();
              supp::Coord = Coord(),
              dims = 2,
              handle = gnuplot_state.current,
              args...)

    ## Process optional keyword arguments.
    axisconf = parse(axis)
    curveconf = parse(args)

    # validate data
    valid_coords(x, y, z, supp)

    # create curve
    c = Curve(x    = x,
              y    = y,
              z    = z,
              supp = supp,
              conf = curveconf)

    # push curve we just created to current figure
    # create new figure
    fig = newfigure(handle, dims=dims, axisconf = axisconf, curve = c)

    # write gnuplot data to file
    write_data(c, fig.dims, fig.datafile)

    return fig
end

### Alternative `plot` methods
plot(x, y, a::Axis = Axis() ; args...) = plot(x, y, Coord(), a ; args...)
# Omit `x` coordinate
plot(y, a::Axis = Axis() ; args...) = plot(1:length(y), y, Coord(), a ; args...)
# Complex vector
plot(c::ComplexCoord ; args...) = plot(real(c) , imag(c) ; args...)
plot(c::ComplexCoord, a::Axis ; args...) = plot(real(c), imag(c), Coord(), a ; args...)
# Function
plot(x, f::Function ; args...) = plot(x, f.(x) ; args...)
plot(x, f::Function, a::Axis ; args...) = plot(x, f.(x), Coord(), a ; args...)

# Add a curve to an existing figure
function plot!(x::Coord,y::Coord, z::Coord = Coord();
               supp::Coord = Coord(),
               dims = 2,
               handle  = gnuplot_state.current,
               args...)

    # Process optional keyword arguments.
    curveconf = parse(args)

    # validate coordinates
    valid_coords(x, y, z, supp)

    # determine handle
    handles = gethandles()
    handle ∈ handles || error("Cannot append curve to non-existing handle")

    # create curve
    c = Curve(x    = x,
              y    = y,
              z    = z,
              supp = supp,
              conf = curveconf)

    # push new curve to current figure
    fig = gnuplot_state.figs[findfigure(handle)]
    push!(fig,c)

    # write gnuplot data to a file
    write_data(c, fig.dims, fig.datafile, append=true)

    return fig
end

### Alternative `plot!` methods
# Omit `x` coordinate
plot!(y ; args...) = plot!(1:length(y), y ; args...)
# Complex vector
plot!(c::ComplexCoord ; args...) = plot!(real(c), imag(c) ; args...)
# Function
plot!(x, f::Function ; args...) = plot!(x, f.(x) ; args...)
