# 2D plots
function plot(x::Coord, y::Coord, z::Coord = Coord();
              gpcom           = "",
              handle::Handle  = gnuplot_state.current,
              financial::FCuN = FinancialCoords(),
              err::ECuN       = ErrorCoords(),
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

    # validate what we can
    valid(ac)
    valid(cc)
    valid(tc)
    valid(x, y, z, err=err, fin=financial)

    # determine handle and clear figure
    handle = figure(handle, redraw = false)
    clearfigure(handle)

    # create curve
    c = Curve(x    = x,
              y    = y,
              z    = z,
              F    = financial,
              E    = err,
              conf = cc)

    # push curve we just created to current figure
    push_figure!(handle,tc,ac,c,gpcom)

    # write gnuplot data to a file
    fig = gnuplot_state.figs[findfigure(handle)]
    write_data(c, fig.datafile)

    return fig
end

# Add a curve to an existing figure
function plot!(x::Coord,y::Coord, z::Coord = Coord();
               handle::Handle  = gnuplot_state.current,
               financial::FCuN = FinancialCoords(),
               err::ECuN       = ErrorCoords(),
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

    # validate what we can
    valid(cc)

    # determine handle
    handles = gethandles()
    handle ∈ handles || error("Cannot append curve to non-existing handle")
    handle = figure(handle, redraw = false)

    # create curve
    c = Curve(x    = x,
              y    = y,
              z    = z,
              F    = financial,
              E    = err,
              conf = cc)

    # push new curve to current figure
    push_figure!(handle,c)

    # write gnuplot data to a file
    fig = gnuplot_state.figs[findfigure(handle)]
    write_data(c, fig.datafile, append=true)

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
surf(x::Coord,y::Coord,z::Coord;args...) = plot(x,y,z;args...)
surf!(x::Coord,y::Coord,z::Coord;args...) = plot!(x,y,z;args...)
surf(x::Coord,y::Coord,f::Function;args...) = plot(x,y,meshgrid(x,y,f);args...) # 3D function
surf!(x::Coord,y::Coord,f::Function;args...) = plot!(x,y,meshgrid(x,y,f);args...) # 3D function
surf(z::Matrix;args...) = surf(1:size(z)[2],1:size(z)[1],z;args...) # matrix
surf!(z::Matrix;args...) = surf!(1:size(z)[2],1:size(z)[1],z;args...) # matrix

# 3-D contour plots
function contour(x::Coord,y::Coord,z::Coord;labels=true,gpcom="",args...)
    gp = gpcom*"""unset key
            set view map
            set contour base
            unset surface
            set cntrlabel font ",7"
            set cntrparam levels 10"""
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

# plot a matrix
function plot(x::Coord,M::Matrix;
              legend     = "",
              linewidth  = "1",
              plotstyle  = config[:curve][:plotstyle],
              linecolor  = config[:curve][:linecolor],
              linestyle  = config[:curve][:linestyle],
              pointtype  = config[:curve][:pointtype],
              pointsize  = config[:curve][:pointsize],
              fillcolor  = config[:curve][:fillcolor],
              fillstyle  = config[:curve][:fillstyle],
              financial  = FinancialCoords(),
              err        = ErrorCoords(),
              handle     = gnuplot_state.current,
              args...)

    # the following arguments need to be vectors
    legend isa Vector{String} && (lg = legend)
    legend isa String && (lg = [legend])
    lgn = length(lg)
    plotstyle isa Vector{String} && (ps = plotstyle)
    plotstyle isa String && (ps = [plotstyle])
    psn = length(ps)
    linecolor isa Vector{String} && (lc = linecolor)
    linecolor isa String && (lc = [linecolor])
    lcn = length(lc)
    linewidth isa Vector{String} && (lw = linewidth)
    linewidth isa String && (lw = [linewidth])
    lwn = length(lw)
    linestyle isa Vector{String} && (ls = linestyle)
    linestyle isa String && (ls = [linestyle])
    lsn = length(ls)
    pointtype isa Vector{String} && (pt = pointtype)
    pointtype isa String && (pt = [pointtype])
    ptn = length(pt)
    pointsize isa Vector{String} && (pz = pointsize)
    pointsize isa String && (pz = [pointsize])
    pzn = length(pz)
    fillcolor isa Vector{String} && (fc = fillcolor)
    fillcolor isa String && (fc = [fillcolor])
    fcn = length(fc)
    fillstyle isa Vector{String} && (fs = fillstyle)
    fillstyle isa String && (fs = [fillstyle])
    fsn = length(fs)
    financial isa Vector{FCuN} && (fn = financial)
    financial isa FCuN && (fn = [financial])
    fnn = length(fn)
    err isa Vector{ECuN} && (er = err)
    err isa ECuN && (er = [err])
    ern = length(er)

    # plot first columnt
    ans = plot(x,M[:,1],
               legend    = lg[1],
               plotstyle = ps[1],
               linecolor = lc[1],
               linewidth = lw[1],
               linestyle = ls[1],
               pointtype = pt[1],
               pointsize = pz[1],
               fillcolor = fc[1],
               fillstyle = fs[1],
               financial = fn[1],
               err       = er[1],
               handle    = handle;
               args...)
    # plot subsequent columns
    for col in 2:Base.size(M)[2]
        ans = plot!(x,M[:,col];
                    legend    = lg[(col-1)%lgn+1],
                    plotstyle = ps[(col-1)%psn+1],
                    linecolor = lc[(col-1)%lcn+1],
                    linewidth = lw[(col-1)%lwn+1],
                    linestyle = ls[(col-1)%lsn+1],
                    pointtype = pt[(col-1)%ptn+1],
                    pointsize = pz[(col-1)%pzn+1],
                    fillcolor = fc[(col-1)%fcn+1],
                    fillstyle = fs[(col-1)%fsn+1],
                    financial = fn[(col-1)%fnn+1],
                    err       = er[(col-1)%ern+1],
                    handle    = gnuplot_state.current)
    end
    return ans
end

