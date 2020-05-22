# 2D plots
function plot(x::Coord, y::Coord, z::Coord = Coord();
              supp::Coord = Coord(),
              dims = 2,
              handle = gnuplot_state.current,
              args...)

    debug("handle = $handle; dims = $dims", "plot")

    ## Process optional keyword arguments.
    axesconf, curveconf = parse(args)

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
    fig = newfigure(handle, dims=dims, axesconf = axesconf, curve = c)

    # write gnuplot data to file
    write_data(c, fig.dims, fig.datafile)

    return fig
end

# Add a curve to an existing figure
function plot!(x::Coord,y::Coord, z::Coord = Coord();
               supp::Coord = Coord(),
               dims = 2,
               handle  = gnuplot_state.current,
               args...)

    # Process optional keyword arguments.
    _, curveconf = parse(args)

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

# Alternative `plot` methods
plot(y::Coord;args...) = plot(1:length(y),y;args...)     # omit `x` coordinate
plot(x::Real,y::Real;args...) = plot([x],[y];args...)    # single real point
plot(c::Complex;args...) = plot(real(c),imag(c);args...) # complex point
plot(c::ComplexCoord;args...) = plot(real(c),imag(c);args...) # complex vector
plot(x::Coord,f::Function;args...) = plot(x,f.(x);args...) # function
plot(M::Matrix;args...) = plot(1:size(M)[1],M;args...) # a matrix

plot!(y::Coord;args...) = plot!(1:length(y),y;args...) # missing `x` coordinate
plot!(x::Real,y::Real;args...) = plot!([x],[y];args...) # single real point
plot!(c::Complex;args...) = plot!(real(c),imag(c);args...) # complex point
plot!(c::ComplexCoord;args...) = plot!(real(c),imag(c);args...) # complex vector
plot!(x::Coord,f::Function;args...) = plot!(x,f.(x);args...) # function

# scatter plots
scatter(x::Coord,y::Coord; args...) = plot(x,y,ps=:points;args...)
scatter(y::ComplexCoord;args...) = scatter(real(y),imag(y);args...) # complex
scatter!(x::Coord,y::Coord;args...) = plot!(x,y,ps=:points;args...)
scatter!(y::ComplexCoord;args...) = scatter!(real(y),imag(y);args...) # complex

# stem plots
function stem(x::Coord,y::Coord;onlyimpulses=false,args...)
    p = plot(x,y;w=:impulses,lc=:blue,lw=1.25,args...)
    onlyimpulses || (p = plot!(x,y;w=:points,lc=:blue,pt="ecircle",pz=1.5,args...))
    return p
end
function stem(y::Coord;args...)
    stem(1:length(y),y;args...)
end
stem(x,f::Function;args...) = stem(x,f.(x);args...)

# bar plots
function bar(x::Coord,y::Coord;args...)
    plot(x,y;ps="boxes",bw="0.8 relative",fs="solid 0.5",args...)
end
bar(y;args...) = bar(1:length(y),y;args...)

# histogram
function histogram(data::Coord;bins::Int=10,norm::Real=1.0,args...)
    # validation
    bins < 1 && throw(DomainError(bins, "at least one bin is required"))
    norm < 0 && throw(DomainError(norm, "norm must be a positive number."))

    x, y = hist(data,bins)
    y = norm*y/(step(x)*sum(y))  # make area under histogram equal to norm

    bar(x, y; boxwidth="0.9 relative", fillstyle="solid 0.5", args...)
end

# Image plots
function imagesc(x::Coord,y::Coord,z::Coord; args...)
    ps = "image"
    ndims(z) == 3 && (ps = "rgbimage")
    plot(x,y,z,ps=ps;args...)
end
imagesc(z::Matrix;args...) = imagesc(1:size(z)[2],1:size(z)[1],z;args...)
imagesc(z::AbstractArray{<:Real,3};args...) = imagesc(1:size(z)[3],1:size(z)[2],z;args...)

# 3-D surface plots
surf(x::Coord,y::Coord,z::Coord;args...) = plot(x,y,z,dims=3;args...)
surf!(x::Coord,y::Coord,z::Coord;args...) = plot!(x,y,z,dims=3;args...)
surf(x::Coord,y::Coord,f::Function;args...) = plot(x,y,meshgrid(x,y,f),dims=3;args...) # 3D function
surf!(x::Coord,y::Coord,f::Function;args...) = plot!(x,y,meshgrid(x,y,f),dims=3;args...) # 3D function
surf(z::Matrix;args...) = surf(1:size(z)[2],1:size(z)[1],z,dims=3;args...) # matrix
surf!(z::Matrix;args...) = surf!(1:size(z)[2],1:size(z)[1],z,dims=3;args...) # matrix

# 3-D contour plots
function contour(x::Coord,y::Coord,z::Coord;labels=true,cntrparam="",gpcom="",args...)
    gp = """unset key
            set view map
            set contour base
            unset surface
            set cntrlabel font ",7"
            set cntrparam $(cntrparam == "" ? "levels 10" : cntrparam)
            $gpcom"""
    p = surf(x,y,z;gpcom=gp,args...)
    labels && (p = surf!(x,y,z;plotstyle="labels"))
    return p
end
contour(x::Coord,y::Coord,f::Function;args...) = contour(x,y,meshgrid(x,y,f);args...)
contour(z::Matrix;args...) = contour(1:size(z)[2],1:size(z)[1],z;args...)

# 3-D scatter plots
scatter3(x::Coord,y::Coord,z::Coord;args...) = surf(x,y,z,ps="points";args...)
scatter3!(x::Coord,y::Coord,z::Coord;args...) = surf!(x,y,z,ps="points";args...)

# 3-D heatmaps
heatmap(x,y,z;gpcom="",args...) = surf(x,y,z,gpcom=gpcom*"set view map",ps=:pm3d;args...)
