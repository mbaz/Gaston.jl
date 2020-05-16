# 2D plots
function plot(x::Coord, y::Coord, z::Coord = Coord();
              supp::Coord = Coord(),
              dims = 2,
              gpcom::String  = "",
              handle::Handle = gnuplot_state.current,
              args...)

    # Create new figure configuration with default values.
    tc = TermConf()
    ac = AxesConf()
    cc = CurveConf()

    ## Process optional keyword arguments.
    # in `title = "graph"`, we call `title` the argument and `"graph"` the value
    for k in keys(args)
        # verify argument is valid
        k in syn_list || throw(ArgumentError("unknown argument $k"))
        # find official name if a synonym was used, store it in `argument`,
        #   and store its value in `value`.
        # the keys of dict `synonyms` are the official argument names
        argument, value = nothing, nothing
        for a in keys(synonyms)
            if k ∈ synonyms[a]
                argument = a
                value = args[k]
                break
            end
        end
        # translate argument to a valid gnuplot command
        value = parse(argument, value)
        # store arguments in figure configuration structs
        for c in (tc, ac, cc)
            if argument in fieldnames(typeof(c))
                setfield!(c, argument, value)
                break
            end
        end
    end

    # validate data
    valid_coords(x, y, z, supp)

    # determine handle and clear figure
    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create curve
    c = Curve(x    = x,
              y    = y,
              z    = z,
              supp = supp,
              conf = cc)

    # push curve we just created to current figure
    push_figure!(handle,tc,ac,c,dims,gpcom)

    # write gnuplot data to file
    fig = gnuplot_state.figs[findfigure(handle)]
    write_data(c, fig.dims, fig.datafile)

    return fig
end

# Add a curve to an existing figure
function plot!(x::Coord,y::Coord, z::Coord = Coord();
               supp::Coord = Coord(),
               dims = 2,
               handle::Handle  = gnuplot_state.current,
               args...)

    # Create a new curve configuration with default values.
    cc = CurveConf()

    # Process optional keyword arguments.
    for k in keys(args)
        # verify argument is valid
        k in syn_list || throw(ArgumentError("unknown argument $k"))
        # find official name if a synonym was used, store it in `argument`,
        #   and store its value in `value`.
        # the keys of dict `synonyms` are the official argument names
        argument, value = nothing, nothing
        for a in keys(synonyms)
            if k ∈ synonyms[a]
                argument = a
                value = args[k]
                break
            end
        end
        # translate argument to a valid gnuplot command
        value = parse(argument, value)
        # store arguments in curve configuration struct
        if argument in fieldnames(CurveConf)
            setfield!(cc, argument, value)
        end
    end

    # validate coordinates
    valid_coords(x, y, z, supp)

    # determine handle
    handles = gethandles()
    handle ∈ handles || error("Cannot append curve to non-existing handle")
    handle = figure(handle, redraw = false)

    # create curve
    c = Curve(x    = x,
              y    = y,
              z    = z,
              supp = supp,
              conf = cc)

    # push new curve to current figure
    push_figure!(handle,c)

    # write gnuplot data to a file
    fig = gnuplot_state.figs[findfigure(handle)]
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
function stem(x::Coord,y::Coord;onlyimpulses=config[:axes][:onlyimpulses],args...)
    p = plot(x,y;ps=:impulses, lc=:blue,lw=1.25,args...)
    onlyimpulses || (p = plot!(x,y;ps=:points,lc=:blue,mk="ecircle",ms=1.5,args...))
    return p
end
function stem(y::Coord;onlyimpulses=config[:axes][:onlyimpulses],args...)
    stem(1:length(y),y;onlyimpulses=onlyimpulses,args...)
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
    ps = "image pixels"
    ndims(z) == 3 && (ps = "rgbimage")
    plot(x,y,z,ps=ps)
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
